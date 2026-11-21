# GAME DESIGN DOCUMENT (GDD)
# GRAPH COLORING – Version 1.0

## 1. Tổng quan sản phẩm

### 1.1. Ý tưởng

Graph Coloring là game giải đố logic trên nền tảng di động. Người chơi cần tô màu các node trong một đồ thị sao cho:

1. Hai node có cạnh nối trực tiếp không được có cùng màu.
2. Mỗi màu phải được sử dụng đúng số lượng quy định.
3. Các node đã bị khóa hoặc cố định không thể thay đổi.
4. Mọi nước đi phải giữ cho bài toán còn ít nhất một lời giải hoàn chỉnh.

Game tập trung vào tư duy logic, khả năng lập kế hoạch và phân bổ tài nguyên. Độ khó tăng dần thông qua cấu trúc đồ thị và các ràng buộc, thay vì chỉ tăng số lượng node.

### 1.2. Định hướng

- Thể loại: Puzzle / Logic / Strategy.
- Nền tảng: Android trước, có thể mở rộng iOS.
- Engine: Flutter.
- Ngôn ngữ: Tiếng Việt và tiếng Anh.
- Mô hình kinh doanh: Free-to-play, Rewarded Ads là nguồn quảng cáo chính.
- Chế độ chơi: Campaign với các level được thiết kế sẵn.
- Đối tượng: Người chơi yêu thích Sudoku, Nonogram, logic puzzle và các game giải đố chiến thuật.

### 1.3. Điểm khác biệt cốt lõi

Không chỉ cần tô hai node kề nhau khác màu, người chơi còn phải quản lý số lượng màu chính xác.

Ví dụ:

Một level có 8 node và 4 màu:

- Đỏ: đúng 2 node.
- Vàng: đúng 2 node.
- Xanh dương: đúng 2 node.
- Xanh lá: đúng 2 node.

Người chơi không thể tùy ý dùng một màu cho nhiều node, kể cả khi các node đó không nằm cạnh nhau.

Đây là sự kết hợp giữa Graph Coloring và bài toán phân bổ tài nguyên có ràng buộc.

---

## 2. Core Gameplay

### 2.1. Mục tiêu của level

Hoàn thành việc tô màu tất cả node sao cho đồng thời thỏa mãn:

- Không có hai node kề nhau cùng màu.
- Số lượng node của mỗi màu bằng đúng inventory yêu cầu.
- Không thay đổi các node cố định.
- Tất cả node đều được tô màu hợp lệ.

Khi tất cả điều kiện được đáp ứng, level hoàn thành.

### 2.2. Cấu trúc màn hình chơi

Màn hình gameplay gồm:

1. **Header**
   - Nút quay lại.
   - Tên chapter.
   - Số level hiện tại.
   - Số lỗi còn lại.

2. **Color Inventory**
   - Hiển thị các màu được phép sử dụng.
   - Hiển thị số lượng đã sử dụng và tổng số lượng yêu cầu.
   - Ví dụ: Đỏ 1/2, Vàng 0/2, Xanh dương 1/2.

3. **Graph Board**
   - Khu vực chính hiển thị đồ thị.
   - Node được kết nối bằng các cạnh.
   - Có thể kéo màu từ inventory và thả trực tiếp lên node.
   - Node đã khóa có giao diện riêng.

4. **Bottom Actions**
   - Undo.
   - Hint.
   - Restart.
   - Pause.

5. **Completion Dialog**
   - Số sao đạt được.
   - Thời gian hoàn thành.
   - Số lần sử dụng Hint.
   - Nút chơi lại hoặc sang level tiếp theo.

### 2.3. Luật kéo thả màu

Người chơi kéo một màu từ Color Inventory và thả vào node chưa được tô.

Khi kéo màu:

- Hiển thị màu đang được kéo.
- Node có thể nhận màu được highlight.
- Node không thể nhận màu được hiển thị trạng thái không hợp lệ.
- Khi thả thành công, màu được gán cho node.
- Inventory được cập nhật ngay lập tức.

Người chơi cũng có thể nhấn vào node đã tô để xóa màu, nếu nước đi đó không phải node cố định.

Nếu màu đã được sử dụng hết số lượng cho phép, người chơi không thể kéo màu đó vào node khác.

### 2.4. Luật xóa và thay đổi màu

- Node thông thường có thể được đổi màu hoặc xóa màu.
- Node cố định không thể thay đổi.
- Khi xóa màu khỏi node, số lượng màu tương ứng được hoàn lại inventory.
- Undo khôi phục trạng thái trước đó, bao gồm cả inventory.
- Không cho phép thao tác làm thay đổi trạng thái của node cố định.

### 2.5. Điều kiện hoàn thành

Level chỉ hoàn thành khi:

- Tất cả node đã được tô màu.
- Không tồn tại hai node kề nhau cùng màu.
- Tất cả inventory màu đều đã sử dụng đủ số lượng.
- Các node cố định vẫn giữ nguyên trạng thái.

Không tự động hoàn thành chỉ vì tất cả node đã có màu.

---

## 3. Hệ thống Node và Graph

### 3.1. Graph

Một level được biểu diễn bằng:

- Nodes: danh sách node.
- Edges: danh sách kết nối giữa các node.
- Colors: danh sách màu có thể sử dụng.
- Inventory: số lượng chính xác của mỗi màu.
- Constraints: các điều kiện bổ sung.
- Initial State: trạng thái ban đầu của level.

### 3.2. Các loại node

**Normal Node**

Node thông thường. Người chơi có thể tô, xóa hoặc đổi màu.

**Locked Node**

Node đã được cố định màu từ đầu level. Người chơi không thể thay đổi màu của node này.

Màu của Locked Node được tính vào inventory tương ứng.

**Restricted Node – dành cho giai đoạn mở rộng**

Node chỉ được phép sử dụng một tập màu nhất định.

Ví dụ: Node A chỉ được sử dụng màu đỏ hoặc vàng.

**Special Node – dành cho giai đoạn mở rộng**

Có thể bổ sung các loại node đặc biệt trong các chapter nâng cao, nhưng không đưa vào phiên bản gameplay đầu tiên.

### 3.3. Quy tắc thiết kế graph

- Không tạo node trùng ID.
- Không tạo cạnh nối một node với chính nó.
- Cạnh trùng lặp phải được loại bỏ.
- Graph phải liên thông, trừ khi level có chủ đích thiết kế nhiều cụm độc lập.
- Không để node bị cô lập nếu không có lý do thiết kế.
- Mỗi level phải có ít nhất một nghiệm hợp lệ.
- Level phải được solver kiểm tra trước khi phát hành.

---

## 4. Hệ thống xử lý sai – No Solution

### 4.1. Nguyên tắc

Đây là cơ chế quan trọng nhất của game.

Người chơi không bị phạt chỉ vì một lựa chọn chưa tối ưu. Người chơi chỉ bị tính lỗi khi nước đi mới khiến bài toán không còn bất kỳ lời giải hợp lệ nào.

Ví dụ:

Một node có thể dùng màu đỏ hoặc vàng. Người chơi chọn màu đỏ. Nếu vẫn tồn tại cách tô hoàn chỉnh cho tất cả node còn lại, nước đi được chấp nhận.

Nếu không còn bất kỳ cách tô hợp lệ nào, nước đi bị từ chối và người chơi mất một lượt lỗi.

### 4.2. Quy trình kiểm tra

Khi người chơi thả màu vào node:

1. Kiểm tra màu còn số lượng trong inventory không.
2. Kiểm tra node có được phép nhận màu đó không.
3. Tạm thời gán màu vào node.
4. Kiểm tra xung đột với các node kề.
5. Chạy solver để kiểm tra khả năng hoàn thành.
6. Nếu còn ít nhất một nghiệm: chấp nhận nước đi.
7. Nếu không còn nghiệm: rollback nước đi và trừ một lượt lỗi.

### 4.3. Số lỗi cho phép

Mỗi level có 2 lượt lỗi miễn phí.

- Lỗi thứ nhất: còn 1 lượt.
- Lỗi thứ hai: hết lượt lỗi.
- Khi hết lượt lỗi: người chơi được chọn xem quảng cáo để tiếp tục hoặc chơi lại level.

Khi tiếp tục bằng Rewarded Ad, người chơi được cộng thêm 2 lượt lỗi.

Giới hạn đề xuất: chỉ cho phép nhận thêm lượt lỗi bằng quảng cáo tối đa 1 lần trong mỗi lần chơi level, nhằm tránh việc người chơi xem quảng cáo liên tục để vượt qua bài toán.

### 4.4. Trải nghiệm khi mắc lỗi

Không nên hiển thị thông báo quá nặng nề.

Thông báo gợi ý:

"Không còn cách hoàn thành với lựa chọn này."

Nước đi không hợp lệ được hoàn tác, node trở về trạng thái trước đó và inventory không bị thay đổi.

---

## 5. Thuật toán Graph Coloring Solver

### 5.1. Mục đích

Solver có ba nhiệm vụ:

1. Xác định level có nghiệm hay không.
2. Kiểm tra nước đi của người chơi có dẫn đến trạng thái không thể hoàn thành hay không.
3. Tạo dữ liệu phục vụ Hint và kiểm thử level.

### 5.2. Mô hình bài toán

Đây là bài toán Constraint Satisfaction Problem (CSP).

Mỗi node là một biến.

Domain của mỗi node là tập màu mà node có thể nhận.

Các ràng buộc:

- Adjacent Constraint: hai node kề nhau phải khác màu.
- Exact Inventory Constraint: tổng số node dùng mỗi màu phải bằng chính xác số lượng quy định.
- Fixed Constraint: node cố định không được đổi màu.
- Restricted Constraint: node chỉ được sử dụng các màu thuộc tập cho phép, nếu có.

### 5.3. Thuật toán đề xuất

Sử dụng kết hợp:

- Backtracking Search.
- Forward Checking.
- MRV (Minimum Remaining Values).
- DSATUR heuristic.
- Exact inventory pruning.

Backtracking đảm bảo solver có thể tìm kiếm nghiệm chính xác. DSATUR và MRV giúp chọn node khó nhất để xử lý trước, giảm không gian tìm kiếm.

### 5.4. Chọn node tiếp theo

Ưu tiên node theo thứ tự:

1. Node có ít màu hợp lệ còn lại nhất (MRV).
2. Nếu bằng nhau, chọn node có nhiều màu khác nhau xuất hiện ở các node kề nhất (DSATUR).
3. Nếu vẫn bằng nhau, chọn node có bậc kết nối cao hơn.

Mục tiêu là xử lý các node bị ràng buộc nhiều trước.

### 5.5. Forward Checking

Sau khi gán một màu cho node:

- Loại màu đó khỏi domain của các node kề.
- Cập nhật số lượng màu còn lại trong inventory.
- Kiểm tra node chưa tô có còn màu hợp lệ không.
- Kiểm tra mỗi màu còn đủ node có thể nhận màu đó không.

Nếu một node không còn màu hợp lệ, nhánh hiện tại thất bại.

Nếu số node tối đa có thể nhận một màu nhỏ hơn số lượng màu còn phải dùng, nhánh hiện tại cũng thất bại.

### 5.6. Exact Inventory Pruning

Ví dụ:

Inventory màu đỏ yêu cầu 2 node.

- Đã sử dụng: 1.
- Còn phải sử dụng: 1.
- Số node chưa tô có thể nhận màu đỏ: 0.

Trạng thái này không thể hoàn thành, solver phải trả về false.

Ngược lại, nếu đã sử dụng đủ 2 node đỏ thì màu đỏ phải bị loại khỏi domain của tất cả node chưa tô.

### 5.7. Pseudocode

```text
function solve(state):
    if all nodes are colored:
        return validate_all_constraints(state)

    node = select_uncolored_node_MRV_DSatur(state)

    for color in get_valid_colors(node, state):
        assign(node, color)

        if forward_checking(state):
            if solve(state):
                return true

        unassign(node, color)

    return false
```

Trong đó `get_valid_colors` phải kiểm tra:

- Node có được phép dùng màu không.
- Màu còn inventory không.
- Không xung đột với node kề.
- Các ràng buộc khác của level.

### 5.8. Kiểm tra nước đi

```text
function validate_move(state, node, color):
    if not inventory_available(color):
        return INVALID

    if not node_accepts_color(node, color):
        return INVALID

    apply_temporary_move(node, color)

    if solve(state):
        commit_move()
        return VALID

    rollback_move()
    return NO_SOLUTION
```

### 5.9. Tối ưu hiệu năng

- Dùng adjacency list thay vì kiểm tra toàn bộ cặp node.
- Duy trì inventory count thay vì tính lại toàn bộ mỗi lần.
- Duy trì domain của node và cập nhật theo thay đổi.
- Có thể cache trạng thái solver bằng state key.
- Dùng early pruning cho inventory và domain.
- Với Undo, ưu tiên lưu delta của thao tác thay vì sao chép toàn bộ graph.
- Solver phải có cơ chế hủy hoặc giới hạn thời gian nếu cần để tránh block UI.

**Lưu ý:** Solver phải trả lời chính xác câu hỏi còn nghiệm hay không. Heuristic chỉ dùng để tối ưu thứ tự tìm kiếm, không được thay thế bước tìm kiếm chính xác.

---

## 6. Hint System

### 6.1. Số lượng Hint

- Người chơi có 3 Hint miễn phí mỗi ngày.
- Khi hết Hint, có thể xem Rewarded Ad để nhận thêm 2 Hint.
- Giới hạn nhận Hint bằng quảng cáo: 3 lần/ngày.

### 6.2. Các loại Hint

**Hint 1 – Highlight Node**

Tô sáng node nên xử lý tiếp theo.

Node được chọn dựa trên MRV/DSATUR.

**Hint 2 – Suggest Color**

Gợi ý một màu hợp lệ cho node được chọn.

**Hint 3 – Explain Constraint**

Giải thích tại sao một lựa chọn cụ thể không thể sử dụng.

Ví dụ:

"Node này chỉ còn có thể sử dụng màu vàng vì các node kết nối trực tiếp đã sử dụng đỏ và xanh dương."

### 6.3. Nguyên tắc Hint

- Hint không được đưa ra lựa chọn khiến level không thể hoàn thành.
- Hint phải dựa trên một nghiệm hợp lệ của trạng thái hiện tại.
- Nếu có nhiều nghiệm, có thể chọn một nghiệm bất kỳ.
- Không nên tiết lộ toàn bộ lời giải chỉ bằng một lần nhấn Hint.

---

## 7. Hệ thống Level và Progression

### 7.1. Cấu trúc Campaign

Game sử dụng các level được thiết kế sẵn.

Không sử dụng chế độ sinh level vô hạn trong phiên bản đầu tiên.

Đề xuất nội dung phát hành:

- 180 level.
- 6 chapter.
- Mỗi chapter có 30 level.
- Mỗi level có một hoặc nhiều cách giải hợp lệ.
- Mọi level phải được kiểm tra bằng solver và playtest thủ công.

### 7.2. Các chapter

**Chapter 1 – First Connection (Level 1–30)**

Mục tiêu: Giới thiệu cách tô màu và luật node kề nhau.

- 4–6 node.
- 2 màu.
- Không có Locked Node.
- Inventory đơn giản.
- Không có node đặc biệt.

**Chapter 2 – Color Balance (Level 31–60)**

Mục tiêu: Làm quen với quản lý inventory chính xác.

- 6–9 node.
- 2–3 màu.
- Bắt đầu xuất hiện graph có nhiều cạnh.
- Inventory mỗi màu được giới hạn chính xác.
- Giới thiệu cơ chế kiểm tra ngõ cụt.

**Chapter 3 – Locked Connections (Level 61–90)**

Mục tiêu: Lập kế hoạch dựa trên các node cố định.

- 8–12 node.
- 3–4 màu.
- Xuất hiện Locked Node.
- Locked Node tiêu thụ inventory.
- Các node còn lại phải được phân bổ dựa trên màu đã cố định.

**Chapter 4 – Complex Network (Level 91–120)**

Mục tiêu: Giải các graph có nhiều ràng buộc.

- 10–15 node.
- 3–4 màu.
- Nhiều node có bậc kết nối cao.
- Inventory khó phân bổ hơn.
- Có các cụm node liên kết chặt.

**Chapter 5 – Restricted Choices (Level 121–150)**

Mục tiêu: Kết hợp nhiều dạng ràng buộc.

- 12–18 node.
- 4–5 màu.
- Bắt đầu giới thiệu Restricted Node.
- Tập màu hợp lệ của từng node có thể khác nhau.
- Locked Node xuất hiện thường xuyên hơn.

**Chapter 6 – Master Network (Level 151–180)**

Mục tiêu: Thử thách khả năng lập kế hoạch tổng thể.

- 15–22 node.
- 4–5 màu.
- Nhiều Locked Node.
- Inventory phân bổ phức tạp.
- Các graph có nhiều điểm nghẽn.
- Có thể yêu cầu người chơi suy luận nhiều bước trước khi tô màu.

Các thông số trên là mục tiêu thiết kế ban đầu, cần điều chỉnh qua playtest. Không nên tăng số node đơn thuần để tạo độ khó.

### 7.3. Độ khó level

Mỗi level có difficulty score dựa trên:

- Số lượng node.
- Số lượng cạnh.
- Số màu.
- Số node có ít lựa chọn.
- Số Locked Node.
- Độ khan hiếm inventory.
- Số bước suy luận bắt buộc.
- Số nghiệm hợp lệ.

Không nên chỉ dựa vào số node.

### 7.4. Mở khóa level

- Level đầu tiên được mở sẵn.
- Hoàn thành level hiện tại để mở level tiếp theo.
- Chapter mới được mở khi hoàn thành chapter trước.
- Người chơi có thể chơi lại level đã hoàn thành.
- Không bắt buộc đạt 3 sao để mở level tiếp theo.

### 7.5. Hệ thống sao

Mỗi level có tối đa 3 sao.

Đề xuất tiêu chí:

- 1 sao: Hoàn thành level.
- 2 sao: Hoàn thành không sử dụng Hint.
- 3 sao: Hoàn thành không sử dụng Hint và không mắc lỗi.

Không dùng thời gian làm điều kiện bắt buộc ở phiên bản đầu tiên để tránh tạo áp lực không cần thiết.

---

## 8. Kinh tế trong game

### 8.1. Nguyên tắc

Game không cần nhiều loại tiền tệ ở phiên bản đầu tiên.

Sử dụng hai tài nguyên chính:

- Energy: giới hạn lượt chơi hằng ngày.
- Hint: hỗ trợ giải đố.

Không cần triển khai Coin Shop hoặc hệ thống nâng cấp phức tạp trong MVP.

### 8.2. Daily Energy

Đề xuất:

- Người chơi có 10 Energy mỗi ngày.
- Mỗi lần thất bại và chọn chơi lại sẽ tiêu thụ 1 Energy.
- Hoàn thành level không tiêu thụ Energy.
- Bắt đầu level mới không tiêu thụ Energy.
- Thoát level giữa chừng và tiếp tục sau đó không tiêu thụ Energy.
- Khi Energy bằng 0, người chơi có thể chờ ngày mới hoặc xem quảng cáo để nhận thêm.

Rewarded Ad:

- Xem một quảng cáo để nhận thêm 3 Energy.
- Giới hạn 3 lần nhận mỗi ngày.
- Energy không vượt quá mức giới hạn tích trữ đề xuất là 10.

Thiết kế này cho phép người chơi có nhiều cơ hội chơi nếu hoàn thành level tốt, đồng thời hạn chế việc liên tục thất bại và khởi động lại.

### 8.3. Daily Hint

- 3 Hint miễn phí mỗi ngày.
- Xem Rewarded Ad nhận thêm 2 Hint.
- Tối đa 3 lần nhận qua quảng cáo mỗi ngày.
- Hint còn lại không bị mất khi người chơi thoát game.
- Reset lượng Hint miễn phí theo ngày.

### 8.4. Continue sau khi hết lượt lỗi

Khi người chơi hết 2 lượt lỗi:

- Chọn xem Rewarded Ad để nhận thêm 2 lượt lỗi.
- Chỉ được tiếp tục bằng quảng cáo tối đa 1 lần trong một lần chơi level.
- Nếu không muốn xem quảng cáo, người chơi có thể chơi lại level nếu còn Energy.

### 8.5. Reset hằng ngày

Daily Energy và Daily Hint được reset theo ngày địa phương của thiết bị, sử dụng Asia/Ho_Chi_Minh làm múi giờ mặc định cho người chơi tại Việt Nam.

Cần lưu ngày reset cuối cùng để tránh việc đóng mở ứng dụng liên tục làm phát sinh tài nguyên mới.

Nếu ứng dụng không có server, dữ liệu local có thể được điều chỉnh bởi người dùng có quyền kiểm soát thiết bị. Đây là giới hạn chấp nhận được trong MVP, nhưng không nên xem local time là cơ chế chống gian lận tuyệt đối.

---

## 9. AdMob Monetization

### 9.1. Định hướng

Rewarded Ads là định dạng quảng cáo chính.

Người chơi chủ động xem quảng cáo để nhận lợi ích. Không nên làm quảng cáo trở thành điều kiện bắt buộc để chơi game.

### 9.2. Rewarded Ad placements

**Placement 1 – Continue Level**

Khi hết lượt lỗi:

- Xem quảng cáo.
- Nhận thêm 2 lượt lỗi.
- Tiếp tục level hiện tại.

**Placement 2 – Get Energy**

Khi hết Energy:

- Xem quảng cáo.
- Nhận 3 Energy.

**Placement 3 – Get Hint**

Khi hết Hint miễn phí:

- Xem quảng cáo.
- Nhận 2 Hint.

### 9.3. Interstitial Ads

Không sử dụng Interstitial trong MVP hoặc chỉ bật sau khi đã có dữ liệu retention đủ tốt.

Nếu triển khai:

- Chỉ hiển thị tại điểm chuyển tiếp tự nhiên, chẳng hạn sau khi hoàn thành một số level.
- Không hiển thị trong lúc giải đố.
- Không hiển thị sau mỗi thao tác.
- Không hiển thị ngay sau khi người chơi vừa xem Rewarded Ad.
- Có frequency cap, đề xuất tối đa 1 lần sau 3 level hoàn thành và không quá 1 lần trong 3 phút.

Các giới hạn này là cấu hình thử nghiệm, cần điều chỉnh dựa trên trải nghiệm thực tế.

### 9.4. Banner Ads

Không ưu tiên Banner Ads trong gameplay vì có thể làm giảm diện tích graph và ảnh hưởng thao tác kéo thả.

Nếu cần thử nghiệm, chỉ đặt ở màn hình Home hoặc Level Selection và không che các nút tương tác.

### 9.5. Quy tắc kỹ thuật AdMob

- Dùng Google Test Ad Unit ID trong môi trường phát triển.
- Chỉ dùng Ad Unit ID production trong bản phát hành.
- Không cấp thưởng nếu quảng cáo chưa xác nhận hoàn thành.
- Nếu quảng cáo không tải được, cho phép người chơi đóng dialog và tiếp tục theo phương án không quảng cáo.
- Tránh gọi show khi quảng cáo chưa load.
- Có loading state và trạng thái lỗi rõ ràng.
- Không tự động mở quảng cáo khi người chơi chưa đồng ý.
- Ghi nhận các sự kiện hiển thị, hoàn thành, nhận thưởng và lỗi để phân tích.

Các Ad Unit ID phải được cấu hình riêng theo nền tảng và môi trường.

---

## 10. UI/UX và Visual Direction

### 10.1. Phong cách

Đề xuất phong cách:

- Minimalist.
- Modern puzzle.
- Màu sắc rõ ràng, tương phản tốt.
- Giao diện sạch, ít chi tiết thừa.
- Animation ngắn, mượt.
- Tập trung vào graph và màu sắc.

### 10.2. Màu sắc

Mỗi màu phải dễ phân biệt trên nền sáng và tối.

Bảng màu ban đầu:

- Red.
- Yellow.
- Blue.
- Green.
- Purple.

Không chỉ dùng màu để biểu đạt trạng thái. Có thể bổ sung pattern hoặc icon cho khả năng tiếp cận người chơi bị khó phân biệt màu.

### 10.3. Animation

- Kéo màu: node được highlight.
- Thả màu hợp lệ: animation fill.
- Nước đi dẫn đến no_solution: node rung nhẹ và màu quay về inventory.
- Hoàn thành level: animation các node sáng lần lượt.
- Mở chapter: transition nhẹ.

Không nên dùng animation quá dài làm chậm nhịp chơi.

### 10.4. Accessibility

- Hỗ trợ âm thanh bật/tắt.
- Hỗ trợ rung bật/tắt.
- Có chế độ màu tương phản cao.
- Có thể chọn màu bằng thao tác chạm thay cho kéo thả.
- Không dùng màu sắc làm dấu hiệu duy nhất để phân biệt trạng thái.

---

## 11. Lưu trữ dữ liệu

### 11.1. Dữ liệu Level

Mỗi level cần lưu:

- ID.
- Chapter ID.
- Level number.
- Node list.
- Edge list.
- Color definitions.
- Exact inventory.
- Initial fixed colors.
- Restricted color domains (nếu có).
- Difficulty.
- Par time tham khảo (không dùng làm điều kiện bắt buộc).
- Solution validation metadata.

### 11.2. Dữ liệu Player

- Current unlocked level.
- Completed levels.
- Stars per level.
- Best completion time.
- Daily Energy.
- Daily Hint.
- Last daily reset date.
- Current level state.
- Sound settings.
- Vibration settings.
- Language.

### 11.3. Lưu trạng thái giữa chừng

Nếu người chơi thoát game giữa một level:

- Lưu các node đã tô.
- Lưu inventory hiện tại.
- Lưu số lỗi còn lại.
- Lưu lịch sử thao tác cần thiết cho Undo.
- Lưu thời điểm cập nhật.

Khi mở lại ứng dụng, người chơi có thể tiếp tục level.

---

## 12. Kiến trúc Flutter đề xuất

Tách biệt Domain, Application và Presentation.

```text
lib/
  features/
    graph_coloring/
      domain/
        entities/
          graph.dart
          graph_node.dart
          graph_edge.dart
          graph_color.dart
          color_inventory.dart
          puzzle_level.dart
          game_state.dart

        algorithms/
          graph_coloring_solver.dart
          backtracking_solver.dart
          forward_checker.dart
          node_selection_heuristic.dart

        services/
          game_validation_service.dart
          hint_service.dart
          difficulty_service.dart

      application/
        graph_coloring_notifier.dart
        graph_coloring_state.dart

      presentation/
        screens/
          home_screen.dart
          level_selection_screen.dart
          game_screen.dart
          result_screen.dart

        widgets/
          graph_board.dart
          graph_node_widget.dart
          graph_edge_widget.dart
          color_inventory_widget.dart
          game_header.dart
          game_actions.dart
          hint_dialog.dart
          game_over_dialog.dart

      data/
        repositories/
          level_repository.dart
          player_progress_repository.dart
          economy_repository.dart

        datasources/
          local_level_datasource.dart
          local_player_datasource.dart

  core/
    ads/
      ad_service.dart
      rewarded_ad_service.dart
      interstitial_ad_service.dart

    storage/
      local_storage_service.dart
```

### 12.1. State Management

Sử dụng Riverpod 3 Notifier.

GraphColoringNotifier chịu trách nhiệm:

- Khởi tạo level.
- Xử lý thao tác tô màu.
- Undo.
- Restart.
- Kiểm tra nước đi.
- Quản lý lỗi.
- Quản lý trạng thái hoàn thành.
- Gọi Hint Service.
- Lưu tiến trình.

Không đưa thuật toán solver vào Widget hoặc trực tiếp xử lý trong UI.

### 12.2. Solver độc lập

Solver nên là một module Dart thuần, không phụ thuộc Flutter Widget.

Lợi ích:

- Có thể kiểm thử thuật toán độc lập.
- Có thể sử dụng khi tạo level.
- Có thể tái sử dụng cho Hint.
- Dễ tối ưu hiệu năng.
- Không làm UI phụ thuộc vào chi tiết thuật toán.

---

## 13. Level Design Pipeline

Mỗi level cần đi qua quy trình:

1. Thiết kế graph.
2. Khai báo số lượng màu chính xác.
3. Khai báo các node cố định.
4. Chạy solver xác nhận có nghiệm.
5. Kiểm tra số nghiệm.
6. Kiểm tra độ khó.
7. Chơi thử thủ công.
8. Điều chỉnh nếu có nhiều lựa chọn không rõ ràng hoặc độ khó bất thường.
9. Đóng gói vào level data.

### 13.1. Kiểm soát số nghiệm

Không bắt buộc mỗi level chỉ có một nghiệm.

Tuy nhiên:

- Level hướng dẫn có thể có nhiều nghiệm.
- Level trung cấp nên có ít nghiệm hơn.
- Level khó có thể thiết kế gần như duy nhất một nghiệm.

Cần đảm bảo mọi nghiệm đều hợp lệ và không có sự khác biệt giữa kết quả solver và gameplay.

### 13.2. Kiểm tra chất lượng

Mỗi level phải vượt qua:

- Không có nghiệm giả.
- Inventory tổng bằng số node cần tô, tính cả Locked Node.
- Không có node bị thiếu cạnh do lỗi dữ liệu.
- Không có node cố định vi phạm adjacency.
- Không có màu được yêu cầu nhưng không node nào có thể sử dụng.
- Không có trạng thái ban đầu đã vô nghiệm.

---

## 14. Analytics và chỉ số đánh giá

Nên theo dõi:

- Level Started.
- Level Completed.
- Level Failed.
- Number of Mistakes.
- Hint Used.
- Rewarded Ad Started.
- Rewarded Ad Completed.
- Energy Exhausted.
- Level Restarted.
- Time to Complete.
- Chapter Completed.

Các chỉ số cần quan tâm:

- Level completion rate.
- Average attempts per level.
- Average hints per level.
- Rewarded Ad opt-in rate.
- D1 retention.
- D7 retention.
- Average session duration.

Nếu người chơi bỏ game ở một level quá nhiều, cần kiểm tra độ khó và chất lượng hướng dẫn trước khi tăng số quảng cáo.

---

## 15. MVP và Roadmap phát triển

### Phase 1 – Core Gameplay

- Graph model.
- Node và Edge.
- Color Inventory.
- Kéo thả màu.
- Kiểm tra node kề.
- Exact inventory.
- Hoàn thành level.

### Phase 2 – Solver

- Backtracking.
- MRV.
- DSATUR.
- Forward Checking.
- Exact Inventory Pruning.
- No Solution validation.

### Phase 3 – Gameplay Features

- Undo.
- Restart.
- 2 lượt lỗi.
- Locked Node.
- Lưu trạng thái level.

### Phase 4 – Campaign

- Level Selection.
- Chapter.
- Progression.
- Sao.
- 30 level đầu tiên.

### Phase 5 – Economy and Ads

- Daily Energy.
- Daily Hint.
- Rewarded Continue.
- Rewarded Energy.
- Rewarded Hint.
- AdMob integration.

### Phase 6 – Content

- Hoàn thiện 180 level.
- Restricted Node.
- Các chapter nâng cao.
- Kiểm thử độ khó.

### Phase 7 – Polish and Release

- Animation.
- Sound.
- Accessibility.
- Analytics.
- Privacy Policy.
- Store listing.
- Closed Testing.
- Production Release.

---

## 16. Phạm vi phiên bản 1.0

### Bao gồm

- Campaign 180 level.
- 6 chapter.
- Drag and Drop.
- Exact Color Inventory.
- Locked Node.
- No Solution validation.
- 2 lượt lỗi mỗi level.
- Undo và Restart.
- Hint.
- Daily Energy.
- Daily Hint.
- Rewarded Ads.
- Lưu tiến trình.
- Tiếng Việt và tiếng Anh.
- Tối đa 3 sao mỗi level.

### Không bao gồm

- Infinite Mode.
- Level Generator cho người chơi.
- Multiplayer.
- PvP.
- Online leaderboard.
- Coin Shop.
- IAP.
- Hệ thống skin phức tạp.
- Các node đặc biệt phức tạp ngoài Restricted Node.

---

## 17. Các quyết định thiết kế đã chốt

| Hạng mục | Quyết định |
|---|---|
| Cơ chế giải đố | Graph Coloring + Exact Inventory |
| Cách tô màu | Drag and Drop |
| Giới hạn màu | Exact |
| Xử lý ngõ cụt | No Solution |
| Số lỗi miễn phí | 2 mỗi level |
| Continue | Rewarded Ad, +2 lỗi |
| Node khóa | Có |
| Solver | Backtracking + Forward Checking + MRV + DSATUR |
| Hint miễn phí | 3 mỗi ngày |
| Rewarded Hint | +2 Hint |
| Energy | 10 mỗi ngày |
| Rewarded Energy | +3 Energy |
| Campaign | 180 level, 6 chapter |
| Infinite Mode | Không |
| Monetization chính | Rewarded Ads |
| Interstitial | Không ưu tiên trong MVP |

## 18. Kết luận

Graph Coloring phiên bản 1.0 được định vị là một game giải đố logic có chiều sâu, trong đó người chơi phải vừa tuân thủ quy tắc tô màu đồ thị vừa quản lý chính xác số lượng màu.

Điểm quan trọng nhất về mặt kỹ thuật là solver phải kiểm tra được khả năng hoàn thành của trạng thái hiện tại. Đây là nền tảng cho cơ chế No Solution, Hint và kiểm thử chất lượng level.

Điểm quan trọng nhất về mặt sản phẩm là độ khó phải đến từ cách thiết kế graph và phân bổ màu, không phải từ việc ép người chơi xem quảng cáo hoặc tăng số node một cách máy móc.

Ưu tiên phát triển một vertical slice hoàn chỉnh gồm gameplay, exact inventory, solver, undo và một nhóm level đầu tiên trước khi đầu tư vào toàn bộ 180 level và hệ thống quảng cáo.