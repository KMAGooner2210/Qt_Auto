
<details>
    <summary><strong>BÀI 2: META OBJECT SYSTEM</strong></summary>

## **BÀI 2: META OBJECT SYSTEM**

### **I.  QOBJECT**

#### **1.1. Macro Q_OBJECT và cơ chế chống sao chép**

##### **1.1.1. Vai trò** 

*  Để một lớp kế thừa từ `QObject` có thể sử dụng các tính năng của MOS, lớp đó bắt buộc phải khai báo macro `Q_OBJECT` ở ngay đầu vùng định nghĩa lớp (thường là private)

			
			class MyObject : public QObject {
					Q_OBJECT
			public:
					explicit MyObject(QObject *parent = nullptr);
			};

* Khi gặp macro này, trình biên dịch MOC - Meta Object Compiler sẽ nhận diện lớp và sinh ra mã nguồn bổ sung trong một tệp nguồn riêng (thường là `moc_*.cpp`)

* Macro này khai báo các phương thức quan trọng như:

	* `metaObject():` 
	
		* Trả về một con trỏ trỏ tới đối tượng `QMetaObject` chứa siêu dữ liệu của lớp
		
	* `qt_metacast():` 
	
		* Thực hiện chuyển đổi kiểu động an toàn tại thời điểm thực thi (tương tự `dynamic_cast` nhưng không phụ thuộc vào RTTI của C++).    

	* `qt_metacall():` 
	
		* Trình phân phối cuộc gọi (dispatcher) để kích hoạt các slot hoặc truy xuất thuộc tính bằng chỉ mục (index).

##### **1.1.2. Cơ chế chống sao chép** 

*  Các đối tượng kế thừa từ QObject không thể sao chép

*  Qt vô hiệu hóa hàm khởi tạo sao chép (copy constructor) và toán tử gán (copy assignment operator) thông qua macro Q_DISABLE_COPY được định nghĩa trong lớp QObject: 

			#define Q_DISABLE_COPY(Class) \
			    Class(const Class &) = delete; \
			    Class &operator=(const Class &) = delete;

	*  **Tính định danh**
	
		* Một QObject đại diện cho một thực thể duy nhất có danh tính riêng, không phải là một giá trị thô. 

		*  Nó có thể có một vị trí cụ thể trong cây phân cấp, giữ các kết nối Signal-Slot riêng, hoặc đang chạy trong một luồng (thread) cụ thể.

		* Việc sao chép một đối tượng như vậy sẽ dẫn đến sự mơ hồ: Đối tượng mới có nên nhận lại các kết nối Signal-Slot của đối tượng cũ hay không?

		*  Nó có thuộc về cùng một đối tượng cha hay không?

	*  **Quản lý tài nguyên**
	
		* Nếu cho phép sao chép, các con trỏ quản lý tài nguyên bên trong (như con trỏ d-pointer trỏ tới dữ liệu private) dễ rơi vào trạng thái giải phóng kép (double free) khi các bản sao bị hủy.
				
#### **1.2.Quản lý bộ nhớ theo mô hình cây phân cấp**

* Qt cung cấp cơ chế quản lý bộ nhớ tự động thông qua mối quan hệ cha-con (Parent-Child relationship) giữa các QObject.

* **Nguyên lý vận hành:**
	
	*  Khi một QObject được khởi tạo với một đối tượng cha (`parent`), hoặc khi phương thức `QObject::setParent(QObject *parent)` được gọi, đối tượng con tự động đăng ký con trỏ của nó vào danh sách quản lý nội bộ của đối tượng cha (`QObjectList`).

				QObject* parentObj = new QObject();
				QObject* childObj = new QObject(parentObj); // childObj tự động đăng ký vào parentObj

	* **Khi đối tượng cha bị hủy (destructed), hàm hủy của nó sẽ duyệt qua danh sách các đối tượng con và tự động giải phóng chúng (delete) trước khi bản thân đối tượng cha hoàn toàn giải phóng khỏi bộ nhớ.**


			//Quá trình hủy trong hàm hủy ~QObject()
			
			QObject::~QObject() {
				
				// 1. Ngắt tất cả kết nối Signal-Slot liên quan tới đối tượng này
				// 2. Duyệt qua danh sách con và hủy chúng
				
				for(QObject *child : d_ptr->children){
					delete child;
				}

				// 3. Loại bỏ bản thân khỏi danh sách con của đối tượng cha (nếu có)
				if (d_ptr->parent){
					d_ptr->parent->d_ptr->children.removeOne(this);
				}
			} 

	* **Lưu ý về thứ tự khởi tạo trên phân vùng Stack**
	
		* Cơ chế hủy tự động hoạt động an toàn nhất khi các đối tượng được cấp phát động trên phân vùng Heap thông qua toán tử `new`
		
		* Tuy nhiên, nếu các đối tượng được khai báo trên phân vùng Stack, việc định nghĩa sai thứ tự khai báo có thể dẫn đến lỗi sập chương trình (crash) do giải phóng bộ nhớ hai lần (double free). 


			// Trường hợp lỗi
	
				void badExample() {
				    QObject child;
				    QObject parent;
				    child.setParent(&parent);
				} 
				// Khi thoát khỏi hàm, 'parent' bị hủy trước. 
				// Hàm hủy của 'parent' gọi delete trên địa chỉ của 'child' (nằm trên Stack) -> Lỗi nghiêm trọng.
				// Sau đó, 'child' ra khỏi phạm vi hoạt động và tự hủy lần thứ hai trên Stack.


			// Trường hợp an toàn
	
				void goodExample() {
				    QObject parent;
				    QObject child(&parent);
				}
				// 'child' được khai báo sau nên bị hủy trước khi thoát khỏi hàm.
				// Hàm hủy của 'child' tự ngắt kết nối và tự gỡ mình ra khỏi danh sách con của 'parent'.
				// Sau đó 'parent' hủy, danh sách con đã trống -> An toàn.
	


### **II.  CƠ CHẾ SIGNAL VÀ SLOT**

#### **2.1. Khai báo và kết nối Signal - Slot với QObject::connect**

##### **2.1.1. Cú pháp khai báo**

* Là các phương thức chỉ được khai báo phần chữ ký trong khối `signals`
	
* Không có phần thân định nghĩa 
	
	* Khi MOC quét qua file tiêu đề và phát hiện khối `signals:`, nó sẽ tự động sinh ra phần thân cho từng Signal trong file `moc_*.cpp`.
		
	* Phần thân được sinh ra có nhiệm vụ duy nhất: duyệt qua danh sách tất cả Slot đang kết nối và gọi lần lượt từng cái với tham số được truyền vào.  
	
* Chúng luôn trả về kiểu `void`  
		
	* Một Signal có thể kết nối tới nhiều Slot cùng lúc.
		
	* Do đó Qt thiết kế Signal luôn là `void` — nó là thông báo một chiều, không phải lời gọi hàm chờ kết quả.   

* Tham số đính kèm
		
	* Mặc dù không trả về giá trị, Signal hoàn toàn có thể mang theo dữ liệu thông qua tham số.
		
	* Dữ liệu này được truyền thẳng vào tất cả Slot kết nối với nó.
		
		* Ví dụ Signal `valueChanged(int newValue)` mang theo giá trị mới mỗi khi Counter thay đổi — tất cả Slot nhận được đều thấy cùng một giá trị đó.  

* VD: Một Signal, nhiều Slot
		
	* Tình huống: Một thanh kéo âm lượng (`VolumeSlider`) thay đổi giá trị, ba thứ khác nhau cần phản ứng nhưng VolumeSlider không nên biết sự tồn tại của chúng.
		
				// VolumeSlider chỉ khai báo Signal - không biết ai sẽ lắng nghe
				class VolumeSlider : public QObject {
					Q_OBJECT
					
				signals:
					void volumeChanged(int newVolume);
				
				public:
					void drag(int value){
						emit volumeChanged(value);
						}
					};

				// Ba Receiver hoàn toàn độc lập với nhau và với VolumeSlider class
				class VolumeLabel : public QObject {
					Q_OBJECT
				public slots:
					void updateText(int value){
						qDebug() << "Hiển thị:" << value << "%";
					}
				}

				class AudioSystem : public QObject {
					Q_OBJECT
				public slots:
					void setVolume(int value){
						qDebug() << "Âm thanh thực tế:" << value;
					}
				};

				class StatusBar : public QObject {
					Q_OBJECT
				public slots:
					void updateIcon(int value){
						qDebug() << "Icon loa cập nhật cho mức:" << value;
					}
				}

				// Bên ngoài, ai muốn lắng nghe thì tự đăng ký — VolumeSlider không cần thay đổi gì:

				int main(){
					VolumeSlider slider;
					VolumeLabel label;
					AudioSystem audio;
					StatusBar bar;

					QObject::connect(&slider, &VolumeSlider::volumeChanged,
									 &label, &VolumeLabel::updateText);
					
					QObject::connect(&slider, &VolumeSlider::volumeChanged,
									 &audio, &VolumeLabel::setVolume);

					QObject::connect(&slider, &VolumeSlider::volumeChanged,
									 &bar, &StatusBar::updateIcon);		

			// Một lần phát Signal — ba Slot cùng được kích hoạt 
			slider.drag(75); 
			
			// Output: 
			// Hiển thị: 75 % 
			// Âm thanh thực tế: 75 
			// Icon loa cập nhật cho mức: 75 }			

##### **2.1.2. Phương thức kết nối QObject::connect**

* `QObject::connect` là hàm thiết lập đường dẫn giữa một Signal và một Slot.
	
* Khi Signal được phát, Qt tự động tìm tất cả Slot đã đăng ký với Signal đó và gọi lần lượt.

* **Cú pháp cũ - String based (Qt 4)** 

			connect(sender, SIGNAL(valueChanged(int)), receiver, SLOT(updateValue(int)));

	* Macro `SIGNAL()` và `SLOT()` hoạt động theo cơ chế đơn giản: chuyển đổi chữ ký hàm thành chuỗi ký tự thuần túy rồi truyền vào Qt để so khớp tại runtime.

			#define SIGNAL(a)  "2"#a   // SIGNAL(valueChanged(int)) → "2valueChanged(int)"
			#define SLOT(a)    "1"#a   // SLOT(updateValue(int))    → "1updateValue(int)"			

	* Qt lưu trữ danh sách tên Signal và Slot dưới dạng chuỗi trong bảng siêu dữ liệu do MOC sinh ra.
	
	* Khi `connect` được gọi, Qt so khớp hai chuỗi đó với bảng này tại thời điểm chạy chương trình. 
	
	* Hệ quả trực tiếp của cơ chế này là mọi lỗi chính tả đều vô hình với trình biên dịch: 

				// Viết sai tên Slot — trình biên dịch không phát hiện được
				connect(sender, SIGNAL(valueChanged(int)), receiver, SLOT(updteValue(int)));
				//                                                         ^^^
				//                                    Thiếu chữ 'a' — chỉ thấy lỗi khi chạy chương trình

* **Cú pháp mới - Pointer to member function (Qt5 / Qt6)** 

			connect(sender, &Counter::valueChanged, receiver, &MyWidger::updateValue);

	* Thay vì chuỗi ký tự, cú pháp này truyền vào con trỏ hàm thực sự của C++
	
	* Trình biên dịch phải kiểm tra sự tồn tại và tính tương thích của hàm ngay tại bước biên dịch — nếu sai, chương trình không biên dịch được, lỗi hiện ra ngay lập tức. 

			// Viết sai tên — lỗi biên dịch ngay, không chạy được
			connect(sender, &Counter::valueChnaged, receiver, &MyWidget::updateValue);
			//                         ^^^
			//              error: no member named 'valueChnaged' in 'Counter'		

* **Ép kiểu ngầm định giữa tham số** 

	* Cú pháp hiện đại cho phép Signal và Slot có kiểu tham số không hoàn toàn giống nhau, miễn là C++ có thể chuyển đổi ngầm định giữa chúng:
	
	* Cú pháp cổ điển sẽ từ chối kết nối này tại runtime vì tên kiểu trong chuỗi không khớp chính xác. 


			class Sensor : public QObject {
			    Q_OBJECT
			signals:
			    void temperatureChanged(double value); // phát ra double
			};

			class Display : public QObject {
			    Q_OBJECT
			public slots:
			    void update(int value) {  // nhận int — vẫn kết nối được
			        qDebug() << "Nhiệt độ:" << value;
			    }
			};

			// Hợp lệ — Qt tự chuyển double → int khi gọi Slot
			connect(&sensor, &Sensor::temperatureChanged, &display, &Display::update);

* **Kết nối trực tiếp với Lambda** 

	* Lambda không có tên, không có địa chỉ có thể biểu diễn bằng chuỗi, nên `SLOT()` không thể dùng cho chúng.
	
	* Cú pháp hiện đại xử lý Lambda như một callable object thông thường:

			Counter counter;

			// Không cần tạo thêm class Receiver — xử lý thẳng tại chỗ
			QObject::connect(&counter, &Counter::valueChanged, [](int newValue) {
			    qDebug() << "Giá trị mới:" << newValue;
			});

			counter.setValue(42);
			// Output: Giá trị mới: 42

	* Lambda đặc biệt hữu ích khi logic xử lý quá đơn giản để đáng tạo cả một class riêng, hoặc khi cần capture biến từ ngữ cảnh xung quanh:

			int threshold = 100;

			QObject::connect(&counter, &Counter::valueChanged, [threshold](int newValue) {
			    if (newValue > threshold) {
			        qDebug() << "Vượt ngưỡng cho phép!";
			    }
			});
				
#### **2.2. Thread Safety**

##### **2.2.1. Bối cảnh**

* Trong ứng dụng đơn luồng, mọi thứ thực thi tuần tự — Signal phát ra, Slot được gọi ngay lập tức, không có xung đột.

* Nhưng khi ứng dụng có nhiều luồng chạy song song, câu hỏi phức tạp hơn xuất hiện:  

	* Slot sẽ thực thi trên luồng nào?
	
	* Ai kiểm soát việc đó?
	
	* Điều gì xảy ra nếu Sender và Receiver thuộc hai luồng khác nhau?		
	
* Qt giải quyết toàn bộ vấn đề này thông qua tham số thứ năm của `QObject::connect` — `Qt::ConnectionType`.

##### **2.2.2. Qt::DirectConnection**

* Slot được gọi trực tiếp như một hàm thành viên thông thường, ngay tại luồng của Sender, ngay tại thời điểm Signal phát ra.

* Sender bị chặn cho đến khi Slot thực thi xong.

			Luồng A (Sender)          Luồng B (Receiver)
			──────────────────         ──────────────────
			emit signal()
			  │
			  ├──► Slot thực thi       ← Slot chạy trên Luồng A, không phải B
			  │    ngay tại đây             
			  │    (Luồng A bị chặn)   
			  ▼
			tiếp tục...
	
	* Nguy hiểm khi dùng sai ngữ cảnh:
	
			// Worker chạy trên luồng nền
			// Display thuộc luồng chính (UI thread)
			connect(&worker, &Worker::dataReady,
			        &display, &Display::updateUI,
			        Qt::DirectConnection);  // ← SAI

			// updateUI() sẽ chạy trên luồng nền — truy cập UI từ luồng nền
			// là hành vi không xác định (undefined behavior) trong Qt


##### **2.2.3. Qt::QueuedConnection**

* Thay vì gọi Slot trực tiếp, Qt đóng gói Signal cùng toàn bộ tham số thành một sự kiện (`QEvent`) và đẩy vào hàng đợi sự kiện (`Event Loop`) của luồng chứa Receiver.

* Slot sẽ thực thi khi luồng đó xử lý đến sự kiện này. 

* Sender không bị chặn — nó phát Signal xong là tiếp tục ngay.

		Luồng A (Sender)              Luồng B (Receiver)
		──────────────────             ──────────────────
		emit signal(data)              Event Loop đang chạy...
		  │                                │
		  ├──► Đóng gói data               │
		  │    thành QEvent                │
		  │    → đẩy vào hàng đợi ─────►  Nhận QEvent
		  │                                │
		  ▼                                ├──► Slot thực thi
		tiếp tục ngay...                   │    trên Luồng B
		                                   ▼
	
	* VD:
	
			// Đúng — updateUI() sẽ chạy trên luồng chính
			connect(&worker, &Worker::dataReady,
			        &display, &Display::updateUI,
			        Qt::QueuedConnection);

##### **2.2.4. Qt::AutoConnection (Mặc định)**

* Qt tự quyết định tại thời điểm Signal được phát, dựa trên việc Sender và Receiver có cùng luồng hay không:

	* Cùng luồng → dùng `DirectConnection`

	* Khác luồng → dùng `QueuedConnection`

			// Không cần chỉ định — Qt tự xử lý đúng trong hầu hết trường hợp
			connect(&worker, &Worker::dataReady, &display, &Display::updateUI);
	
##### **2.2.5. Qt::BlockingQueuedConnection**

* Giống `QueuedConnection` nhưng Sender bị khóa lại, chờ cho đến khi Receiver thực thi xong Slot mới tiếp tục.

* Dùng khi Sender cần kết quả xử lý từ Receiver trước khi tiếp tục.


		Luồng A (Sender)              Luồng B (Receiver)
		──────────────────             ──────────────────
		emit signal()
		  │
		  ├──► Đóng gói → hàng đợi ──────► Slot thực thi
		  │                                 │
		  │    [Luồng A bị khóa,            │
		  │     chờ tại đây]                │
		  │                         ◄────── Slot xong, gửi tín hiệu mở khóa
		  ▼
		tiếp tục...

* Nguy cơ Deadlock nghiêm trọng nếu dùng sai:

		// Nếu Sender và Receiver cùng một luồng:
		// Sender phát Signal → bị khóa chờ Receiver
		// Receiver không bao giờ chạy được vì luồng đang bị Sender khóa
		// → Deadlock vĩnh viễn

##### **2.2.6. Nguyên lý truyền tham số trong QueuedConnection**

* Vì Slot không thực thi ngay lập tức, tham số cần được **sao chép và lưu trữ** trong hàng đợi cho đến khi Slot chạy.

* Qt thực hiện điều này thông qua Meta-Type System — một cơ chế biết cách sao chép và hủy từng kiểu dữ liệu an toàn.

* Các kiểu có sẵn như `int`, `double`, `QString`, `QList` đã được đăng ký sẵn.

* Với kiểu tự định nghĩa, lập trình viên phải đăng ký thủ công qua hai bước:  


			// Bước 1 — Khai báo ở cấp độ file (ngoài hàm)
			// Cho Qt biết kiểu này tồn tại và có thể dùng trong Meta-Type System
			struct UserData {
			    int id;
			    QString name;
			};
			Q_DECLARE_METATYPE(UserData)

			// Bước 2 — Đăng ký tại runtime trong main(), trước khi connect
			// Cung cấp cho Qt khả năng sao chép và hủy UserData khi truyền qua hàng đợi
			int main() {
			    qRegisterMetaType<UserData>();

			    // Từ đây connect với QueuedConnection mới hoạt động đúng
			    connect(&worker, &Worker::userLoaded,
			            &display, &Display::showUser,
			            Qt::QueuedConnection);
			}
		
### **III.  HỆ THỐNG QUẢN LÝ THUỘC TÍNH ĐỘNG**

#### **3.1. Macro Q_PROPERTY**

		Q_PROPERTY(type name
		           READ getFunction
		           [WRITE setFunction]
		           [RESET resetFunction]
		           [NOTIFY notifySignal]
		           [DESIGNABLE bool]
		           [SCRIPTABLE bool]
		           [STORED bool]
		           [USER bool]
		           [BINDABLE bindableProperty]
		           [CONSTANT]
		           [FINAL])

* Các thành phần chính:

	* **type name**:
	
		*  Kiểu dữ liệu (ví dụ: int, QString) và tên của thuộc tính (ví dụ: volume). 
	
	* **READ getFunction**:
	
		* Chỉ định hàm đọc giá trị
		
		* Hàm này bắt buộc phải là `const` vì đọc không được phép thay đổi trạng thái đối tượng

				int volume() const {
					return m_volume;
				} 
	
	* **WRITE setFunction**:
	
		* Chỉ định hàm ghi giá trị
		
		* Hàm này nhận tham số kiểu tương ứng hoặc `const &`

				void setVolume(int newVolume){
				...
				}
		
	* **NOTIFY notifySignal**:
	
		* Chỉ định Signal sẽ phát ra khi giá trị thay đổi
		
		* Thiếu `NOTIFY` thì QML và các cơ chế Data Binding không thể biết khi nào cần cập nhật giao diện 
		
				void setVolume(int newVolume){
				...
				}  
	
* VD:

		class Player : public QObject {
				Q_OBJECT
				Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
		public:
			explicit Player(QObject *parent = nullptr) : QObject(parent) , m_volume(0) {}
			int volume() const {
				return m_volume;
			}

		void setVolume(int newVolume){
				if(m_volume != newVolume){
					m_volume = newVolume;
					emit volumeChanged(m_volume);  // NOTIFY
				}
			}

		signals:
				void volumeChanged(int newVolume);
		private:
				int m_volume;
		}
		
* Truy cập động qua tên chuỗi:

	* Sau khi khai báo `Q_PROPERTY`, Qt cho phép đọc và ghi thuộc tính mà không cần biết kiểu cụ thể của đối tượng tại compile-time

				QObject *obj = new Player();
			
				// Ghi - Qt tìm hàm WRITE tương ứng và gọi setVolume(80)
				obj->setProperty("volume", 80);

				// Đọc - Qt tìm hàm READ tương ứng và gọi volume()
				int currentVolume = obj->property("volume").toInt(); 
	
		*  Kiểu dữ liệu (ví dụ: int, QString) và tên của thuộc tính (ví dụ: volume). 


#### **3.2. Thuộc tính liên kết tự động - QBindable**

* **Vấn đề với Signal-Slot khi đồng bộ nhiều biến phụ thuộc:**

	* Giả sử có ba biến: `price`, `taxRate`, và `total = price * (1 + taxRate)`
	
		* Với Signal-Slot thuần túy, lập trình viên phải tự viết kết nối để mỗi khi `price` hoặc `taxRate` thay đổi thì tính lại `total`
		
		* Khi số lượng biến phụ thuộc tăng lên, mạng lưới kết nối này nhanh chóng trở nên khó quản lý 
		
		* `QProperty<T>` sinh ra để thay thế toàn bộ mạng lưới đó bằng một biểu thức quan hệ khai báo một lần    

* **Nguyên lý hoạt động:**

			#include <QProperty>
			#include <QDebug>

			class Subscription {
			public:
				QProperty<double> price {0.0};
				QProperty<double> taxRate{0.1};
				QProperty<double> total;

				Subscription(){
					total.setBinding([this]() {
						return price.value() * (1.0 + taxRate.value());
					});
				}
			};

	* Giả sử có ba biến: `price`, `taxRate`, và `total = price * (1 + taxRate)`

	* Khi `price` hoặc `taxRate` thay đổi, Qt biết `total` phụ thuộc vào chúng vì Lambda đã gọi `.value()` của cả hai trong lúc binding được thiết lập

	* Qt theo dõi mối quan hệ này tự động

			subscription sub;
			sub.price = 100.0
			sub.taxRate = 0.08;

			qDebug() << sub.total.value();  // Lúc này mới tính: 100 * 1.08 = 108.0

			#include <QProperty>
			#include <QDebug>

* **Lazy Evaluation:**

	* Khi `price` thay đổi, `total` **không tính lại ngay** — nó chỉ được đánh dấu trạng thái `dirty` (không còn hợp lệ).
	
	* Phép tính thực sự chỉ xảy ra khi `.value()` được gọi. 

				price = 200        price = 300        price = 400
				   │                   │                   │
				   ▼                   ▼                   ▼
				total → dirty      total → dirty      total → dirty
				                                           │
				                                    total.value() được gọi
				                                           │
				                                           ▼
				                                    Tính toán một lần: 400 * 1.08

	* Nếu `price` thay đổi 100 lần liên tiếp trước khi `.value()` được gọi, Qt chỉ thực hiện đúng **một lần tính toán** thay vì 100 lần — đặc biệt có giá trị khi biểu thức tính toán phức tạp hoặc liên quan đến nhiều thuộc tính.


### **IV. TRÌNH BIÊN DỊCH MOC**

#### **4.1. Bối cảnh**

* C++ tiêu chuẩn không có cơ chế phản chiếu (reflection) tại runtime — nghĩa là một chương trình C++ đang chạy không thể tự hỏi:

	* Class này có những hàm nào?
	
	* Tham số kiểu gì?
	
	* Signal nào đang kết nối với Slot nào?
	
* Đây chính xác là những thông tin mà hệ thống Signal-Slot, Property System và QML cần để hoạt động.
		
* MOC sinh ra để lấp đầy khoảng trống đó — nó đọc code C++ của lập trình viên và **sinh thêm code C++** chứa toàn bộ siêu dữ liệu mà Qt cần.

#### **4.2. Quy trình phân tích và sinh mã**

* MOC không phải trình biên dịch C++ — nó là một **công cụ phân tích và sinh mã** chạy trước trình biên dịch thực sự.

		[ Tệp tiêu đề (.h) ]
		               │
		               ▼
		     ┌───────────────────┐
		     │       MOC         │ ◄─── Phát hiện Q_OBJECT
		     └───────────────────┘
		               │
		               ▼
		     [ moc_*.cpp ]  ──────┐
		                          ├──► [ Trình biên dịch C++ ] ──► [ Tệp thực thi ]
		     [ Tệp nguồn .cpp ] ──┘
	
* **Giai đoạn 1 - Phân tích cú pháp (Parsing)**
		
	* MOC quét qua các file tiêu đề `.h` 
	
	* Khi phát hiện macro `Q_OBJECT`,nó đọc toàn bộ cấu trúc class đó: danh sách Signal,Slot, thuộc tính `Q_PROPERTY`, và các enum được khai báo với `Q_ENUM`
	
	* MOC không đọc file `.cpp` - chỉ file `.h`  

* **Giai đoạn 2 - Sinh mã (Code Generation)**
		
	* MOC tạo ra file `moc_[tên_file].cpp` chứa ba thành phần cốt lõi:
	
		* String Table - Bảng chuỗi mô tả toàn bộ class:

				// Mã MOC tự sinh
				
				static const uint qt_meta_data_Counter[] = {
					// Mô tả: tên class, số lượng Signal, số lượng Slot
					// Tên từng hàm, kiểu từng tham số,...
				};

				static const char qt_meta_stringdata_Counter[] = {
					"Counter\0valueChanged\0newValue\0setValue\0value\0"
					// ^tên class ^tên signal ^tham số ^slot	
			    };
				
	
		* Thân hàm của Signal

				// MOC sinh ra thân hàm cho Signal valueChanged
				void Counter::valueChanged(int newValue)
				{
				    // Kích hoạt tất cả Slot đang kết nối với Signal này
				    QMetaObject::activate(this, &staticMetaObject, 0, 
				                          reinterpret_cast<void**>(&newValue));
				}

			* Khi lập trình viên viết `emit valueChanged(5)`, thực chất là đang gọi hàm này — hàm do MOC sinh ra, không phải do lập trình viên viết.


		* Hàm phân phối `qt_metacall` - Cho phép gọi Slot theo chỉ số:

				// MOC sinh ra — dùng để kích hoạt Slot theo index thay vì tên
				int Counter::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
				{
				    _id = QObject::qt_metacall(_c, _id, _a);
				    if (_id < 0) return _id;
				    if (_c == QMetaObject::InvokeMetaMethod) {
				        switch (_id) {
				        case 0: valueChanged(*reinterpret_cast<int*>(_a[1])); break; // Signal
				        case 1: setValue(*reinterpret_cast<int*>(_a[1])); break;     // Slot
				        }
				    }
				    return _id;
				}

			* Đây là cơ chế cho phép Qt gọi Slot qua `QueuedConnection` — thay vì lưu con trỏ hàm, Qt chỉ cần lưu chỉ số (index) của Slot và gọi `qt_metacall` với chỉ số đó khi cần.


#### **4.3. Tích hợp tự động với CMake**

* Trong dự án thực tế có hàng chục hoặc hàng trăm file tiêu đề, việc chạy MOC thủ công cho từng file là không thể.

* CMake giúp giải quyết điều này 

			cmake_minimum_required(VERSION 3.16)
			project(QtAppExample VERSION 1.0 LANGUAGES CXX)

			set(CMAKE_CXX_STANDARD 17)
			set(CMAKE_CXX_STANDARD_REQUIRED ON)

			# Một dòng này kích hoạt toàn bộ quy trình MOC tự động
			set(CMAKE_AUTOMOC ON)

			find_package(Qt6 COMPONENTS Core REQUIRED)

			add_executable(QtAppExample
			    main.cpp
			    myclass.h
			    myclass.cpp
			)

			target_link_libraries(QtAppExample PRIVATE Qt6::Core)

* Nguyên lý hoạt động của AUTOMOC:

					CMake quét toàn bộ file được khai báo trong add_executable
		               │
		               ▼
		    Phát hiện Q_OBJECT trong myclass.h
		               │
		               ▼
		    Lên lịch chạy: moc myclass.h → moc_myclass.cpp
		               │
		               ▼
		    Tự động thêm moc_myclass.cpp vào danh sách biên dịch
		               │
		               ▼
		    Trình biên dịch C++ xử lý: main.cpp + myclass.cpp + moc_myclass.cpp
		               │
		               ▼
		                [ QtAppExample — tệp thực thi ]

	* Nếu thêm `Q_OBJECT` vào một class nhưng quên khai báo file `.h` tương ứng trong `add_executable`, CMake sẽ không quét file đó và MOC sẽ không sinh mã — dẫn đến lỗi linker với thông báo khó hiểu như `undefined reference to 'vtable for ClassName'`
						    	 			
   </details> 


<details>
    <summary><strong>BÀI 3: CẤU TRÚC QML</strong></summary>

## **BÀI 3: CẤU TRÚC QML**

### **I.  QML**

#### **1.1. Khái niệm** 

*  Trước khi có QML, lập trình viên xây dựng giao diện Qt hoàn toàn bằng C++ — tạo từng widget, thiết lập từng thuộc tính, kết nối từng Signal-Slot bằng code.

* Cách này hoạt động được nhưng có một vấn đề cốt lõi: **code mô tả giao diện và code xử lý logic trộn lẫn vào nhau**, khó đọc, khó thay đổi thiết kế mà không đụng đến logic.  

* QML giải quyết điều này bằng cách tách biệt hoàn toàn hai mối quan tâm đó. 

#### **1.2. Các thành phần cơ sở**			

##### **1.2.1. Lớp Item và Rectangle** 

*  **Item:**

	* `Item` là lớp cơ sở của mọi thành phần trực quan trong QML
	
	* Bản thân nó không vẽ gì lên màn hình - không màu nền, không viền, không nội dung
	
	* Nhưng nó định nghĩa toàn bộ hệ thống tọa độ và hành vi mà mọi thành phần con kế thừa   

	*  Các thuộc tính Item cung cấp chia thành 4 nhóm:
	
		* **Định vị hình học** - `x`, `y`, `width`, `height`, `z`
		
			* Tọa độ `x` và `y` luôn là tương đối so với đối tượng cha, không phải tọa độ tuyệt đối của màn hình  

		* **Biến đổi không gian** - `scale` (thu phóng), `rotation` (xoay quanh tâm)
		
			* Các biến đổi này ảnh hưởng đến cả đối tượng lẫn toàn bộ cây con bên trong nó  
		
		* **Trạng thái hiển thị** - `opacity` (từ 0.0 đến 1.0), `visible`
		
			* `opacity: 0` và `visible: false` khác nhau 
			
			* `opacity: 0` vẫn chiếm không gian và nhận sự kiện chuột 
			
			* `visible: false` thì không  

		* **Trạng thái hiển thị** - `opacity` (từ 0.0 đến 1.0), `visible`
		
			* `opacity: 0` và `visible: false` khác nhau 
			
	*  **Cơ chế neo giữ** - `anchors`
	
		* Đây là hệ thống định vị tương đối mạnh nhất trong QML, cho phép gắn cạnh của một phần tử vào cạnh của phần tử khác mà không cần tính toán tọa độ thủ công.


				Item {
					id: rootContainer
					width: 400
					height: 300

					Item {
						x: 50      // Cách cạnh trái của cha 50px
						y: 50      // Cách cạnh trên của cha 50px
						width: parent.width * 0.5   // Bằng nửa chiều rộng cha
						height: 100
				   }
			     }
				 
*  **Rectangle:**

	* `Rectangle` kế thừa toàn bộ `Item` và bổ sung khả năng vẽ hình học cơ bản
	
	* `color` - màu nền, nhận giá trị hex, tên màu CSS, hoặc đối tượng `Qt.rgba()`: 
	
			color: "#2c3e50"     // Hex
			color: "transparent" // Trong suốt
			color: Qt.rgba(1, 0, 0, 0.5)  // Đỏ, 50% opacity
	
	* `border.color` và `border.width` - viền được vẽ bên trong ranh giới hình học
	
		* Một rectangle rộng 100px với viền 10px thực ra chỉ có vùng nền màu rộng 80px - viền ăn vào trong, không mở rộng ra ngoài
		    

	* `radius` - bo góc
	
		* Khi `radius` bằng một nửa `width` và `height` (với hình vuông), Rectangle trở thành hình tròn hoàn hảo
		
				Rectangle {
				    width: 60
				    height: 60
				    radius: 30    // Hình tròn
				    color: "#3498db"
				}

	* `gradient` - chuyển màu tuyến tính qua các điểm dừng màu `GradientStop`:
	
			Rectangle {
			    width: 200
			    height: 200
			    color: "#2c3e50"
			    border.color: "#3498db"
			    border.width: 2
			    radius: 10

			    gradient: Gradient {
			        GradientStop { position: 0.0; color: "#3498db" }
			        GradientStop { position: 1.0; color: "#2c3e50" }
			    }
			}
				

##### **1.2.2. Text và Image** 

*  **Text: Hiển thị văn bản**

	* Phần tử `Text` kết xuất chuỗi ký tự với hệ thống định dạng đầy đủ thông qua nhóm thuộc tính `font`:
	
			Text {
			    width: 150
			    text: "Tài liệu kỹ thuật lập trình hệ thống Qt/QML"
			    font.pixelSize: 14
			    font.bold: true
			    wrapMode: Text.WordWrap      // Tự động xuống dòng theo từ
			    elide: Text.ElideRight       // Cắt ngắn với "..." nếu vượt width
			    horizontalAlignment: Text.AlignLeft
			}
	
	* `wrapMode`: quyết định cách ngắt dòng chỉ hoạt động khi `width` được xác định rõ ràng
	
		* `Text.WordWrap` chỉ ngắt tại khoảng trắng giữa từ
		
		* `Text.WrapAnywhere` ngắt tại bất kỳ ký tự nào
		
	* `elide`: chỉ có tác dụng khi **không** dùng `wrapMode`, nó cắt ngắt văn bản một dòng và thêm `...`
	
		* `Text.ElideRight` cắt ở cuối
		
		* `Text.ElideMiddle` cắt ở giữa
	
*  **Image: Hiển thị hình ảnh và tối ưu bộ nhớ**

	* Phần tử `Image` hỗ trợ PNG, JPEG, SVG và cả URL từ mạng
	
	* Vấn đề hiệu năng xuất hiện khi ảnh gốc có độ phân giải lớn nhưng chỉ hiển thị ở kích thước nhỏ 

			// SAI về mặt tối ưu bộ nhớ
			Image {
			    width: 100
			    height: 100
			    source: "photo_4000x3000.jpg"
			    // Qt vẫn giải mã toàn bộ ảnh 4000×3000 vào RAM
			    // rồi mới thu nhỏ xuống 100×100 để hiển thị
			    // → Lãng phí ~144MB RAM cho một ảnh 100px
			}

	* Giải pháp với `sourceSize`
	
		* `sourceSize` can thiệp vào quá trình giải mã, không phải quá trình hiển thị - đó là lý do tại sao nó tiết kiệm bộ nhớ thực sự
		
		* Còn `width/height` chỉ thu nhỏ ảnh sau khi đã giải mã toàn bộ  
	
			Image {
			    width: 100
			    height: 100
			    source: "photo_4000x3000.jpg"
			    sourceSize.width: 100
			    sourceSize.height: 100
			    // Qt chỉ giải mã ảnh ở kích thước 100×100 ngay từ đầu
			    // → Tiết kiệm bộ nhớ đáng kể
			}

	* Tải bất đồng bộ với `asynchronous`:
	
				Image {
				    width: 100
				    height: 100
				    source: "https://example.com/large-image.png"
				    asynchronous: true     // Giải mã trên luồng phụ — UI không bị chặn
				    cache: true            // Lưu kết quả vào bộ đệm — lần sau không giải mã lại
				    sourceSize.width: 100
				    sourceSize.height: 100
				}  

### **II.  CƠ CHẾ LIÊN KẾT DỮ LIỆU TỰ ĐỘNG - PROPERTY BINDING**

#### **2.1. Bối cảnh** 

* Trong lập trình giao diện truyền thống, khi kích thước cửa sổ thay đổi, lập trình viên phải tự viết code lắng nghe sự kiện resize, tính toán lại kích thước từng phần tử, rồi gán lại từng giá trị.

* Với giao diện phức tạp, đây là công việc lặp đi lặp lại và dễ sai.

* Property Binding giải quyết điều này bằng cách cho phép lập trình viên **khai báo quan hệ** thay vì khai báo từng bước cập nhật.

#### **2.2. Liên kết tĩnh và liên kết động**			

##### **2.2.1. Liên kết tĩnh - Khai báo tại thời điểm định nghĩa** 

*  Dấu hiệu nhận biết liên kết tĩnh là dấu `:` trong khai báo thuộc tính.

* Bất cứ khi nào vế phải của `:` tham chiếu đến một thuộc tính khác, QML tự động thiết lập mối quan hệ theo dõi:
	
			Rectangle {
			    id: container
			    width: 400
			    height: 300

			    Rectangle {
			        id: innerBox
			        width: parent.width * 0.5   // Liên kết — luôn bằng nửa chiều rộng cha
			        height: parent.height - 50  // Liên kết — luôn kém chiều cao cha 50px
			    }
			}
	
	* Khi QML engine phân tích biểu thức `parent.width * 0.5`, nó tự động đăng ký `innerBox.width` là một  người quan sát  của `parent.width`

	* Mỗi khi `parent.width` phát Signal `widthChanged`, engine tính lại biểu thức và cập nhật `innerBox.width` — toàn bộ diễn ra tự động, không cần một dòng code xử lý nào.
	
##### **2.2.2. Phá vỡ liên kết** 

* Liên kết tĩnh bị phá vỡ ngay lập tức khi dùng toán tử gán `=` trong JavaScript:

			Rectangle {
			    id: container
			    width: 400

			    Rectangle {
			        id: innerBox
			        width: parent.width * 0.5  // Liên kết đang hoạt động
			    }

			    MouseArea {
			        anchors.fill: parent
			        onClicked: {
			            innerBox.width = 200
			            // Dòng này làm HAI việc:
			            // 1. Gán giá trị 200 cho innerBox.width
			            // 2. XÓA HOÀN TOÀN liên kết "parent.width * 0.5"
			            // Từ đây, khi container thay đổi kích thước,
			            // innerBox.width sẽ đứng yên tại 200 — không còn cập nhật nữa
			        }
			    }
			}

##### **2.2.3. Liên kết động** 

*  Khi cần thiết lập liên kết từ bên trong code JavaScript (ví dụ sau một sự kiện), phải dùng `Qt.binding()` thay vì gán `=` trực tiếp:

		Rectangle {
		    id: root
		    width: 400
		    height: 300

		    Rectangle {
		        id: box
		        width: 100  // Giá trị ban đầu cố định
		    }

		    Component.onCompleted: {
		        // Gán = sẽ phá vỡ liên kết — Qt.binding() tạo liên kết mới
		        box.width = Qt.binding(function() {
		            return root.width * 0.8;
		        });
		        // Từ đây box.width = root.width * 0.8 và tự cập nhật như liên kết tĩnh
		    }
		}


#### **2.3. Binding Loop**			

##### **2.3.1. Bản chất** 

*  Vòng lặp liên kết xảy ra khi hai thuộc tính phụ thuộc lẫn nhau tạo thành chu trình khép kín — A phụ thuộc B, B phụ thuộc A:

		Rectangle {
		    id: rect
		    width: height * 2   // width phụ thuộc height
		    height: width / 2   // height phụ thuộc width
		}

	* Khi engine cố tính `width`, nó cần biết `height`. Để tính `height`, nó cần biết `width`, QML engine phát hiện chu trình này và in cảnh báo:		

			QML Rectangle: Binding loop detected for property "width"

	* Engine tự ngắt chu trình tại một điểm tùy ý để tránh crash — hệ quả là giao diện hiển thị sai kích thước mà không có thông báo lỗi rõ ràng nào khác.

##### **2.3.2. Kỹ thuật phòng tránh** 

*  Xác định luồng dữ liệu một chiều

			// SAI — chu trình hai chiều
			Rectangle {
			    width: height * 2
			    height: width / 2
			}

			// ĐÚNG — luồng một chiều rõ ràng
			Rectangle {
			    width: 200          // Nguồn gốc cố định
			    height: width / 2   // Phụ thuộc một chiều vào width
			}

*  Dùng signal handler thay vì liên kết hai chiều
		
		Rectangle {
		    id: rect
		    width: 200
		    height: 100

		    // Khi width thay đổi, cập nhật height một chiều
		    onWidthChanged: {
		        height = width / 2
		        // Đây là gán tĩnh — không tạo liên kết ngược
		    }
		}

#### **2.4. Tích hợp và tối ưu mã lệnh JavaScript**			

##### **2.4.1. Bối cảnh** 

*  QML dùng JavaScript để xử lý logic giao diện — phản ứng với sự kiện, tính toán giá trị, điều hướng trạng thái.

* Trên máy tính x86/x64 hiện đại, chi phí này thường không đáng kể.

* Nhưng trên các thiết bị nhúng dùng vi xử lý ARM — màn hình ô tô, thiết bị y tế, bảng điều khiển công nghiệp — cùng một đoạn JavaScript có thể là nguyên nhân khiến giao diện giật hoặc drop frame. 
	

	
##### **2.4.2. Phạm vi thực thi và `.pragma library`** 

* **Inline Scope:**

	* Khi viết JavaScript trực tiếp trong file QML, code đó chạy trong ngữ cảnh của đối tượng QML chứa nó — có thể truy cập trực tiếp các thuộc tính và đối tượng xung quanh:  

			Button {
			    id: myButton
			    onClicked: {
			        myButton.text = "Đã kích hoạt"
			        // Truy cập trực tiếp myButton, parent, các id khác trong file
			    }
			}

* **.pragma library**

	* Khi logic đủ phức tạp để đáng tách ra file riêng, Qt cung cấp hai chế độ cho file `.js`:
	
	* **Chế độ thông thường**  
	
		* Mỗi component import file JS sẽ nhận một bản sao ngữ cảnh riêng.
	
		* Biến toàn cục trong file JS không chia sẻ giữa các component: 

				// utils.js — chế độ thông thường
				var callCount = 0;   // Mỗi component import sẽ có biến callCount riêng

	* **Chế độ .pragma library**  
	
			// helper.js
			.pragma library   // Khai báo Singleton — phải là dòng đầu tiên

			var globalCounter = 0;   // Chia sẻ cho toàn bộ ứng dụng

			function incrementCounter() {
			    globalCounter++;
			    return globalCounter;
			}

			function clamp(value, min, max) {
			    return Math.max(min, Math.min(max, value));
			}

	* **Hạn chế**  
	
		* Hàm bên trong không thể truy cập đối tượng QML trực tiếp — không có `parent`, không có `id`, không có ngữ cảnh QML nào cả.
		
		* Mọi dữ liệu cần xử lý phải truyền qua tham số:

				// SAI — không hoạt động trong .pragma library
				function updateButton() {
				    myButton.text = "Done"   // myButton không tồn tại trong ngữ cảnh này
				}

				// ĐÚNG — truyền dữ liệu qua tham số, trả về kết quả
				function formatLabel(value, unit) {
				    return value.toFixed(2) + " " + unit
				}								



		    	 			
   </details> 


<details>
    <summary><strong>BÀI 4: AUTOMOTIVE GRAPHICS</strong></summary>

## **BÀI 4: AUTOMOTIVE GRAPHICS**

### **I.  THƯ VIỆN QT QUICK CONTROLS 2**

#### **1.1. Các thành phần tương tác và trạng thái** 

*  Mọi component trong QQC2 đều có cấu trúc tách biệt hai lớp:

		┌─────────────────────────────────────────┐
		│          Qt Quick Control 2             │
		└────────────────────┬────────────────────┘
		                     │
		      ┌──────────────┴──────────────┐
		      ▼                             ▼
		┌──────────────┐           ┌──────────────┐
		│ contentItem  │           │  background  │
		│ (nội dung)   │           │  (khung nền) │
		└──────────────┘           └──────────────┘  

* Logic điều khiển (giá trị, trạng thái, sự kiện) nằm trong component, còn cách hiển thị hoàn toàn được kiểm soát qua hai cổng `background` và `contentItem`.

* **Dial - Núm xoay:**

	* Mô phỏng cơ chế xoay vật lý, dùng để điều chỉnh các thông số liên tục như nhiệt độ điều hòa, mức gió, âm lượng:

			Dial {
				from: 16      // Nhiệt độ tối thiểu
				to: 30	      // Nhiệt độ tối đa
				value: 22     // Giá trị hiện tại
				stepSize: 0.5 // Mỗi bước nhảy 0.5 độ

				// pressed = true khi người dùng đang giữ và xoay
				// Dùng để kích hoạt phản hồi xúc giác
				onPressedChanged: {
					if (pressed) hapticEngine.vibrate()
				}
			}

* **Dial - Núm xoay:**

	* Mô phỏng cơ chế xoay vật lý, dùng để điều chỉnh các thông số liên tục như nhiệt độ điều hòa, mức gió, âm lượng:

			Dial {
				from: 16      // Nhiệt độ tối thiểu
				to: 30	      // Nhiệt độ tối đa
				value: 22     // Giá trị hiện tại
				stepSize: 0.5 // Mỗi bước nhảy 0.5 độ

* **ProgressBar - Thanh tiến trình:**

	* Hiển thị dữ liệu trạng thái một chiều — người dùng chỉ đọc, không tương tác.
	
	* Dùng cho SOC pin xe điện, mức nhiên liệu, tiến độ OTA update: 

			ProgressBar {
			    from: 0
			    to: 100
			    value: batteryLevel   // Liên kết trực tiếp với dữ liệu C++

			    // indeterminate: true khi chưa biết thời gian hoàn thành
			    // Hiển thị animation chạy vô hạn thay vì thanh tiến trình tĩnh
			    indeterminate: otaUpdate.isCalculating
			}


* **Slider - Thanh trượt:**

	* Cho phép người dùng trượt tuyến tính để thay đổi giá trị — độ sáng màn hình, độ nhạy, ...
	
			Slider {
			    orientation: Qt.Horizontal   // hoặc Qt.Vertical
			    from: 0
			    to: 100
			    value: screenBrightness

			    onValueChanged: displaySystem.setBrightness(value)
			}

* **Button - Nút nhấn:**

	* Kích hoạt sự kiện rời rạc.
	
	* Thuộc tính `checkable` biến Button thành nút bật/tắt giữ trạng thái — phù hợp cho các chức năng như sấy kính, bật/tắt camera lùi: 
	
			Button {
			    text: "SEAT HEAT"
			    checkable: true     // Giữ trạng thái on/off

			    // checked: true khi đang bật, false khi đang tắt
			    // pressed: true chỉ trong lúc đang nhấn giữ
			    // hovered: true khi con trỏ đang ở trên nút (màn hình cảm ứng không dùng)
			    onCheckedChanged: seatHeating.setActive(checked)
			}


#### **1.2. Styling Override**			

*  Trong ứng dụng ô tô thương mại, giao diện phải tuân theo nhận diện thương hiệu (brand identity) của từng hãng xe — màu sắc, font chữ, hình dạng nút bấm đều được quy định nghiêm ngặt.

* Giao diện mặc định của QQC2 không đáp ứng được điều này.
	
* QQC2 giải quyết bằng cách cho phép **thay thế hoàn toàn** hai lớp hiển thị mà không ảnh hưởng đến logic bên trong:
	
			import QtQuick 2.15
			import QtQuick.Controls 2.15

			Button {
			    id: control
			    text: "AC CONTROL"
			    checkable: true

			    // Thay thế hoàn toàn lớp nền — vẫn giữ nguyên logic pressed/checked
			    background: Rectangle {
			        implicitWidth: 150
			        implicitHeight: 50

			        // Màu thay đổi theo trạng thái checked
			        color: control.checked ? "#1abc9c" : "#2c3e50"

			        // Viền thay đổi theo trạng thái pressed
			        border.color: control.pressed ? "#3498db" : "#34495e"
			        border.width: 2
			        radius: 8
			    }

			    // Thay thế hoàn toàn lớp nội dung
			    contentItem: Text {
			        text: control.text
			        font.pixelSize: 14
			        font.bold: true

			        // Màu chữ thay đổi theo trạng thái checked
			        color: control.checked ? "#ffffff" : "#bdc3c7"
			        horizontalAlignment: Text.AlignHCenter
			        verticalAlignment: Text.AlignVCenter
			    }
			}

	* `control.checked`, `control.pressed`, `control.text` trong các block `background` và `contentItem` là **liên kết trực tiếp** vào trạng thái của Button.
	
	* Khi người dùng nhấn nút, `control.pressed` thay đổi → `border.color` tự cập nhật ngay lập tức mà không cần viết một dòng xử lý sự kiện nào. 
				


### **II.  QT RESOURCE SYSTEM**

#### **2.1. Bối cảnh** 

* Ứng dụng desktop thông thường đọc file hình ảnh, font chữ, QML từ ổ cứng tại runtime — đơn giản và linh hoạt.

* Nhưng trên hệ thống Automotive chạy QNX hay Embedded Linux, cách tiếp cận đó có rủi ro thực sự: xe đang chạy trên đường xóc, bộ nhớ flash bị rung lắc, đọc file có thể thất bại; hoặc đơn giản hơn, file bị xóa nhầm, đường dẫn sai, hệ thống file bị hỏng.

* Qt Resource System giải quyết triệt để bằng cách biên dịch toàn bộ tài nguyên vào thẳng file thực thi

#### **2.2. Biên dịch tài nguyên với qt_add_resources và đường dẫn qrc: /**			

##### **2.2.1. Cơ chế hoạt động** 

*  Thay vì đọc file từ đĩa tại runtime, Qt chuyển đổi từng file tài nguyên thành một mảng byte tĩnh trong C++ tại thời điểm build.

* Mảng này được liên kết thẳng vào file thực thi nhị phân:
	
		images/speedometer.png  ──►  static const unsigned char speedometer_png[] = { 0x89, 0x50, ... };
		fonts/Roboto-Bold.ttf   ──►  static const unsigned char roboto_bold_ttf[] = { 0x00, 0x01, ... };
	
	* Kết quả: ứng dụng là **một file nhị phân duy nhất** chứa toàn bộ giao diện, hình ảnh và font — không phụ thuộc vào bất kỳ file ngoài nào.
	
##### **2.2.2. Cấu hình CMake** 

			qt_add_resources(AutomotiveHMI "resources"
			    PREFIX "/"           # Tiền tố đường dẫn ảo
			    FILES
			        "images/speedometer.png"
			        "images/fuel_icon.svg"
			        "fonts/Roboto-Bold.ttf"
			)

##### **2.2.3. Truy cập qua đường dẫn ảo qrc:/** 

*  Sau khi biên dịch, Qt tạo ra một hệ thống file ảo trong RAM.

* Ứng dụng truy cập bằng tiền tố `qrc:/` — Qt tự điều hướng đến mảng byte tương ứng trong bộ nhớ, hoàn toàn bỏ qua bước I/O đĩa: 

			Image {
			    source: "qrc:/images/speedometer.png"
			    // Qt không đọc file — tra cứu địa chỉ mảng byte trong RAM và trả về ngay
			}

			FontLoader {
			    source: "qrc:/fonts/Roboto-Bold.ttf"
			}

#### **2.3. Chi phí CPU/GPU**			

##### **2.3.1. Vector - SVG** 

*  SVG lưu trữ hình ảnh dưới dạng phương trình toán học XML

*  Không có pixel nào được lưu sẵn — GPU phải tính toán và vẽ từng pixel từ các công thức đó mỗi khi cần hiển thị (quá trình gọi là rasterization):

		File SVG: <circle cx="50" cy="50" r="40" stroke="black"/>
		              ↓
		GPU phải tính: "Pixel nào nằm trên đường tròn tâm (50,50) bán kính 40?"
		              ↓
		Tính từng pixel → ghi vào texture buffer → hiển thị



##### **2.3.2. Raster - PNG** 

*  PNG lưu trữ ảnh điểm đã được nén (lossless).

* Giải mã nhanh hơn SVG vì không cần tính toán hình học.

* Nhưng khi đưa vào VRAM để GPU sử dụng, PNG phải được **giải nén hoàn toàn** thành dạng RGBA8888 thô:  

		File PNG 500KB  ──► Giải nén ──►  Texture RGBA8888 trong VRAM: 4000×3000×4 byte = ~46MB

*  Băng thông truyền dữ liệu từ RAM lên VRAM là tài nguyên giới hạn — đặc biệt trên SoC Automotive nơi CPU và GPU dùng chung bộ nhớ.
		
##### **2.3.3. Nén phần cứng - ETC2 / ASTC** 

*  Ảnh được nén theo khối (block-based compression) và **giữ nguyên dạng nén ngay cả khi đã nạp vào VRAM**.

* GPU có phần cứng giải nén tích hợp, tự giải nén mỗi block khi cần lấy mẫu — không tốn băng thông truyền tải, không tốn RAM/VRAM bổ sung:

		PNG 46MB trong VRAM  ──►  ETC2 tương đương: ~6MB trong VRAM
		                          Giảm băng thông bộ nhớ 6-8 lần


### **III.  HIỆU ỨNG THỊ GIÁC VÀ HOẠT ẢNH**

#### **3.1. Xây dựng luồng hoạt ảnh** 

##### **3.1.1. Property Animation** 

* `PropertyAnimation` thay đổi giá trị một thuộc tính từ điểm đầu đến điểm cuối trong khoảng thời gian xác định.

			PropertyAnimation {
			    target: speedometerNeedle
			    property: "rotation"
			    from: -120
			    to: 120
			    duration: 1500   // 1.5 giây
			}

##### **3.1.2. Sequential Animation** 

* Các bước hoạt ảnh chạy nối tiếp nhau — bước sau chỉ bắt đầu khi bước trước hoàn thành:

			SequentialAnimation {
			    // Bước 1 chạy xong → Bước 2 mới bắt đầu
			    PropertyAnimation { target: gauge; property: "opacity"; to: 1.0; duration: 500 }
			    PropertyAnimation { target: needle; property: "rotation"; to: 120; duration: 1500 }
			}

##### **3.1.3. Parallel Animation** 

* Nhiều hoạt ảnh khởi chạy cùng một lúc, kết thúc theo thời gian riêng của từng cái:

			ParallelAnimation {
			    // Cả hai chạy đồng thời từ cùng một thời điểm
			    PropertyAnimation { target: needle; property: "rotation"; to: 120; duration: 1500 }
			    PropertyAnimation { target: glowEffect; property: "opacity"; to: 0.8; duration: 1500 }
			}
						
#### **3.2. Easing Curves - Mô phỏng kim đồng hồ**			

*  Chuyển động tuyến tính (`Easing.Linear`) — tốc độ không đổi từ đầu đến cuối — không tồn tại trong thế giới vật lý.

* Mọi vật thể có khối lượng đều gia tốc khi bắt đầu và giảm tốc khi dừng.

* Easing curve là hàm toán học ánh xạ thời gian thực thi (0.0 → 1.0) sang tiến trình hoạt ảnh theo đường cong phi tuyến thay vì đường thẳng.

* **`Easing.OutCubic`**

	* Giảm tốc mượt mà, không vượt ngưỡng.
	
	* Phù hợp cho kim đồng hồ tốc độ tăng khi đạp ga: 

			PropertyAnimation {
			    property: "rotation"
			    to: targetAngle
			    duration: 300
			    easing.type: Easing.OutCubic
			    // Nhanh lúc đầu, chậm dần khi tiến gần đích
			    // Cảm giác: kim "lao" về phía giá trị mới rồi dừng mượt
			}	

* **`Easing.OutBack`**

	* Vượt ngưỡng nhẹ rồi nảy về
	
	* Mô phỏng đúng quán tính cơ học của đồng hồ analog vật lý:

			PropertyAnimation {
			    property: "rotation"
			    to: targetAngle
			    duration: 300
			    easing.type: Easing.OutBack
			    easing.overshoot: 1.2   // Kiểm soát mức độ vượt ngưỡng
			    // Kim vượt qua vị trí đích ~20% rồi nảy về
			    // Cảm giác: hoàn toàn giống đồng hồ cơ học thật
			}	

* **`Easing.InOutQuad`**

	* Gia tốc đầu, giảm tốc cuối, đối xứng.
	
	* Phù hợp cho chuyển cảnh màn hình và thanh tiến trình:

			PropertyAnimation {
			    property: "opacity"
			    duration: 400
			    easing.type: Easing.InOutQuad
			    // Mờ dần đều ở đầu và cuối — chuyển cảnh tự nhiên
			}	
				

#### **3.2. Canvas và ShaderEffect**			

*  **Canvas - Vẽ tùy ý bằng CPU**

	* Canvas cung cấp API vẽ trực tiếp kiểu HTML5, phù hợp cho đồ thị động hoặc các hình học không thể tạo bằng Rectangle thông thường:

			Canvas {
			    id: customGauge
			    width: 200
			    height: 200

			    onPaint: {
			        var ctx = getContext("2d")
			        ctx.reset()
			        ctx.strokeStyle = "#3498db"
			        ctx.lineWidth = 8
			        ctx.beginPath()
			        // Vẽ cung tròn chỉ số năng lượng từ -180° đến 0°
			        ctx.arc(100, 100, 80, -Math.PI, 0)
			        ctx.stroke()
			    }
			}

	* Canvas phù hợp cho nội dung vẽ một lần hoặc cập nhật không thường xuyên, không phải animation liên tục.

*  **ShaderEffect - Vẽ bằng GPU**

	* Khi cần hiệu ứng phức tạp chạy liên tục ở 60 FPS — phát sáng, sóng ánh sáng, hiệu ứng nhiễu — `ShaderEffect` can thiệp trực tiếp vào GPU pipeline thông qua GLSL:

			ShaderEffect {
			    width: 200
			    height: 200

			    // Biến QML tự động ánh xạ thành uniform trong GLSL
			    property real uTime: 0.0
			    property color uGlowColor: "#00ffcc"

			    // uTime tăng liên tục — tạo animation động trong shader
			    NumberAnimation on uTime {
			        from: 0; to: 100
			        duration: 100000
			        loops: Animation.Infinite
			    }

			    fragmentShader: "
			        varying highp vec2 qt_TexCoord0;
			        uniform lowp float qt_Opacity;
			        uniform highp float uTime;
			        uniform lowp vec4 uGlowColor;

			        void main() {
			            highp vec2 uv = qt_TexCoord0 - vec2(0.5);
			            highp float dist = length(uv);
			            // Sóng ánh sáng lan ra từ tâm theo thời gian
			            highp float wave = sin(dist * 20.0 - uTime * 5.0) * 0.5 + 0.5;
			            gl_FragColor = uGlowColor * wave * (1.0 - dist * 2.0) * qt_Opacity;
			        }
			    "
			}


		    	 			
   </details> 




