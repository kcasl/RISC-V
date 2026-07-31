# Problem 2: Optimization — 보고서 본문 (사진 사이 삽입용)

사용법: 아래 `[그림 …]` 자리에 스크린샷/파형을 넣고, 그 사이 문단을 그대로 옮기면 됩니다.  
실측: t=3194 µs, s=2280.5 Kbits, S_overall≈2.309.  
조건(과제 PDF): Ti=To=16, 100 MHz, WIDTH=HEIGHT=128 고정, 베이스라인 t0=3930 µs, s0=4280 Kbits.

---

## Problem 2: Optimization

### 1. Optimization

#### (a) Problem and scopes

베이스라인 CNN 가속기(`cnn_accel`)는 128×128 입력에 대해 3개 레이어 ESPCN을 Ti=To=16, 동작 주파수 100 MHz로 수행한다. 과제에서 제시한 베이스라인 성능은 실행 시간 t0=3930 µs, 온칩 버퍼 s0=4280 Kbits이며, 전체 개선도는 S_overall=(t0/t)×(s0/s)로 평가한다. 여기서 클록 주파수, Ti/To, 입출력 해상도는 변경할 수 없으므로, 개선은 데이터 이동·제어 공백·버퍼 구조를 바꾸는 쪽으로만 가능하다.

베이스라인의 버퍼 구성을 분해하면 대략 입력 영상 버퍼 128 Kbits, 피처맵 더블 버퍼 2048×2=4096 Kbits, 가중치·bias/scale 약 55 Kbits 수준으로, s0의 대부분이 피처맵 두 장에 묶여 있다. 시간 측면에서는 라인마다 긴 HSYNC 공백(약 160 사이클)과, 레이어 3에서 Cout=4인데 To=16인 점 때문에 커널 유휴 비율이 큰 것이 병목으로 알려져 있다. 본 최적화는 `hw/cnn_accel_opt`에서 위 제약을 지키면서 실행 시간과 버퍼를 동시에 줄이는 것을 범위로 한다.

[그림 삽입: 베이스라인 버퍼/데이터패스 구조도 또는 과제 Figure]

---

#### (b) Optimization methods

강의에서 제시된 방향은 (1) 입력 재배치와 DMA 트랜잭션 수 감소, (2) DMA와 convolution 파이프라이닝으로 입력 버퍼 축소, (3) Layer 3에서 convolution 커널 완전 활용, (4) layer fusion이다. 본 설계는 기능 동등성을 지키는 선에서 효과가 큰 항목을 적용하였고, 아래에 **수정 코드**를 함께 적는다. 주요 파일: `cnn_accel.v`, `cnn_fsm.v`, `top_system.v`, `top_system_tb.v`.

**1) DMA 패킹 (4 px/word)**  
`butterfly_32bit_reorder.hex`를 쓰고 라인당 전송을 WIDTH/4로 줄였다.

```verilog
// top_system_tb.v
parameter N_WORD = WIDTH * HEIGHT / 4;
parameter INIT_FILE = "img/butterfly_32bit_reorder.hex";
parameter N_CELL = 304;
```

```verilog
// cnn_accel.v
parameter PIX_PER_WORD = 4;
num_trans_ld = q_width / PIX_PER_WORD;          // 32 beats/line
start_addr_ld <= start_addr_ld + q_width;       // byte stride
// unpack one AHB word -> 4 pixels
in_img[in_pixel_count + 0] <= data_o_ld[ 7: 0];
in_img[in_pixel_count + 1] <= data_o_ld[15: 8];
in_img[in_pixel_count + 2] <= data_o_ld[23:16];
in_img[in_pixel_count + 3] <= data_o_ld[31:24];
```

[그림 삽입: reorder hex / INIT 캡처(선택)]

**2) HSYNC=2 + DATA prefetch**  
하단 할로를 DATA에서 `lb_next`로 읽고 HSYNC에서만 시프트한다.

```verilog
// top_system_tb.v
q_start_up_delay = q_is_first_layer ? 12'd160 : 12'd420;
q_hsync_delay    = 12'd2;
```

```verilog
// cnn_accel.v — prefetch address during DATA
fmap_buf_addrb = (row + 2) * q_width + lb_pref_cnt;
// HSYNC: shift window, install lb_next (or zeros on last row)
if(ctrl_hsync_run && (ctrl_hsync_cnt == 0) && (row >= 1)) begin
    // sw_linebuf << one row; bottom <= lb_next
end
```

**3) 단일 fmap + 3-line buffer**  
두 번째 DPRAM 삭제, `sw_linebuf`/`lb_next`로 할로 유지.

```verilog
localparam LINE_BUF_WORDS   = 3 * WIDTH;   // n = 3
localparam LB_PRELOAD_WORDS = 2 * WIDTH;   // [pad0, row0, row1]
reg [To*ACT_BITS-1:0] sw_linebuf [0:LINE_BUF_WORDS-1];
reg [To*ACT_BITS-1:0] lb_next    [0:WIDTH-1];

dpram #(...) u_fmap_buff(...);  // one bank only
// L2/L3 din from sw_linebuf[tap_r*WIDTH+col] with zero padding
```

[그림 삽입: 단일 fmap + linebuf 구조도]

**4) L3 multipixel**은 마지막 행 끝 픽셀 오류로 최종본에서 비활성(`col_stride=1`).  
**5) Weight SPRAM:** `parameter N_CELL = 304; // 16+144+144` (was 432).
---

#### (c) Evaluation

기능 검증은 최적화된 설계를 Vivado에서 `top_system_tb`로 시뮬레이션한 뒤, `out/convout_ch01.bmp`~`ch04.bmp`를 얻고 MATLAB `check_hardware_results.m`으로 `out_sw/ofmap_L03_ch*.bmp`와 비교한다. 네 채널 모두 픽셀 단위로 일치해야 하며(`max_diff == 0`), 이는 과제에서 요구한 “optimized code functions correctly as the baseline”에 해당한다.

[그림 삽입: MATLAB same! 콘솔 출력 4채널]

[그림 삽입: HW 출력 BMP 예시(선택)]

과제에서 요구한 대로 실행 시간 t와 버퍼 크기 s를 보고하고, 전체 개선도는 아래 지표로 측정한다.

\[
S_{\mathrm{overall}} = \left(\frac{t_0}{t}\right) \times \left(\frac{s_0}{s}\right)
\]

여기서 \(t_0\), \(s_0\)는 베이스라인의 실행 시간·버퍼 크기이고, \(t\), \(s\)는 본 최적화 설계의 값이다. 과제 제시값: \(t_0=3930\,\mu\mathrm{s}\), \(s_0=4280\,\mathrm{Kbits}\).

워드에 넣을 평문: `S_overall = (t0/t) × (s0/s)`

버퍼 크기 s는 선언된 온칩 저장 요소의 합으로 계산한다. 입력 버퍼 in_img는 128×128×8=128 Kbits, 피처맵 뱅크 하나는 128×128×16×8=2048 Kbits, 3줄 라인버퍼는 3×128×16×8=48 Kbits, prefetch 줄 lb_next는 128×16×8=16 Kbits, 가중치는 약 39 Kbits, bias와 scale은 약 1.5 Kbits이다. 합하면

\[
s = 128+2048+48+16+39+1.5 = 2280.5\,\mathrm{Kbits}
\]

이므로 \(s_0/s = 4280/2280.5 \approx 1.877\)이다. s0에서 가장 크던 fmap 두 장 중 한 장을 줄인 효과가 지배적이다.

실행 시간 t는 시뮬레이션에서 `OPT DONE: t = 3194 us`로 측정되었다(\(t=3194\,\mu\mathrm{s}\)). 대입하면

\[
S_{\mathrm{overall}}
= \frac{3930}{3194} \times \frac{4280}{2280.5}
\approx 1.230 \times 1.877
\approx 2.309
\]

이다. 시간 약 1.23배, 버퍼 약 1.88배 개선으로 전체 지표는 약 **2.31**이다.

[그림 삽입: TB 콘솔의 OPT DONE / t=3194 us 로그]

---

### 2. Optimality analysis

본 절에서는 선택한 파라미터가 왜 그 값인지, 과제 PDF에 예시로 나온 “입력 버퍼를 줄이기 위해 미리 읽는 라인 수 n”과 같은 관점에서 설명한다.

먼저 라인 윈도우 크기 n=3을 고른 이유를 말한다. 3×3 convolution은 출력 좌표 (r,c)를 계산할 때 입력 행 r−1, r, r+1이 필요하다. 따라서 슬라이딩 윈도우의 최소·충분 높이는 3이다. n=2로 줄이면 할로가 부족해 경계와 내부 결과가 틀어지고, n=4 이상으로 늘리면 추가 SRAM만 커질 뿐 정확도 이득이 없다. 두 번째 전체 fmap(2048 Kbits)과 비교하면 3줄은 48 Kbits에 불과하므로, “피처맵 더블 버퍼를 라인 버퍼로 대체한다”는 선택이 버퍼 지표 s0/s에 가장 직접적으로 기여한다. 여기에 다음 하단 줄을 담는 lb_next 16 Kbits를 더해도 약 64 Kbits로, 제거한 뱅크 하나에 훨씬 못 미친다.

다음으로 첫 행 초기화 방식을 고른 이유를 말한다. 출력 행 0에서는 위 이웃이 존재하지 않으므로 윈도우는 [패드0, 입력0, 입력1]이어야 한다. 초기에 fmap 행 0·1·2를 그대로 [0,1,2]로 넣으면 중심 탭이 한 줄 밀려 상단 수 행이 크게 틀어진다. 그래서 초기 적재는 2×WIDTH 워드만 fmap에서 읽어 중간·하단을 채우고 상단은 0으로 두며, START_UP은 가중치 로드와 이 적재를 덮을 수 있게 L2/L3에서 420으로 두었다. 이후 행으로 넘어갈 때마다 HSYNC에서 한 줄씩 밀어 올리고, DATA 중에 미리 읽어 둔 다음 하단 줄을 붙인다.

HSYNC=2를 고른 이유는 공백을 줄이되 윈도우 갱신에 필요한 최소 시간을 남기기 위해서이다. 하단 줄 prefetch를 DATA에 겹치면 HSYNC에서는 레지스터 시프트만 수행하면 되므로 이론상 1사이클이면 충분하고, 2는 여유 사이클이다. 반대로 prefetch 없이 HSYNC 동안 128워드를 읽으려면 HSYNC를 대략 WIDTH 이상으로 다시 늘려야 해서 시간 이득이 사라진다. 즉 HSYNC≈2는 “n=3 라인버퍼 + DATA 구간 prefetch”와 한 세트로 최적에 가깝다.

DMA 패킹 인수 4는 버스 폭과 픽셀 폭의 비에서 자연스럽게 정해진다. 1픽셀/워드로 두면 트랜잭션이 네 배가 되고, 8픽셀 이상으로 무리하게 묶으면 정렬·재배치 복잡도가 커지며 기존 AHB 32 bit 경로와도 맞지 않는다. reorder hex는 하드웨어가 기대하는 바이트 순서에 맞춘 전처리로, 소프트웨어 기준 영상과 동일한 공간 순서를 `in_img`에 복원하기 위한 것이다.

가중치 N_CELL=304는 실제 필요 하한이다. 레이어별 워드 수가 16, 144, 144로 고정되어 있으므로 432워드 할당은 Problem 1에서 지적한 “최대 크기 단순 할당”과 같은 suboptimal이다. bias/scale은 레이어당 To=16개씩 3레이어라 총량이 작아 s에 미치는 영향은 부차적이다.

마지막으로, Layer 3 multipixel(픽셀 그룹 스트라이드 4)을 최종 설계에서 뺀 이유를 최적화 관점에서 정리한다. Cout=4, To=16이면 커널 인덱스 i를 (pixel=⌊i/4⌋, oc=i%4)로 두면 이론상 L3 계산을 약 4배 줄일 수 있어 S_time에 유리하다. 그러나 마지막 행의 마지막 픽셀 묶음에서 기준 BMP와 불일치가 남아, 과제 평가의 전제인 기능 동등성을 해칠 수 있었다. 버퍼 이득(s0/s≈1.88)만으로도 S_overall의 상당 부분을 확보할 수 있고, 잘못된 출력으로 검증을 통과하지 못하는 설계는 지표가 좋아도 성립하지 않으므로, 현 단계에서는 정확도를 제약으로 두고 multipixel을 보류하는 편이 합리적이다. 입력 버퍼를 n줄만 남기는 DMA–L1 완전 파이프라인 역시 동일하게, L1 스케줄을 DMA와 엄밀히 맞추는 제어 비용이 큰 반면 줄일 수 있는 양은 128 Kbits뿐이라, 우선순위상 fmap 뱅크 제거보다 뒤이다.

정리하면, 본 최적화가 고른 핵심 파라미터는 n=3(및 prefetch 1줄), HSYNC=2, DMA 패킹 4, N_CELL=304이며, 실측 결과 \(t=3194\,\mu\mathrm{s}\), \(s=2280.5\,\mathrm{Kbits}\), \(S_{\mathrm{overall}}\approx 2.309\)이다.

[그림 삽입: s 분해 표 또는 before/after 버퍼 비교]

[그림 삽입: S_overall 계산식과 숫자 정리]

---

## 측정 결과 요약

| 항목 | 베이스라인 | 최적화 |
|---|---|---|
| \(t\) | 3930 µs | **3194 µs** |
| \(s\) | 4280 Kbits | **2280.5 Kbits** |
| \(t_0/t\) | — | ≈ 1.230 |
| \(s_0/s\) | — | ≈ 1.877 |
| \(S_{\mathrm{overall}}\) | — | ≈ **2.309** |

- `check_hardware_results.m` 결과: 채널 1~4 모두 same / (아니면 차이 기록)
