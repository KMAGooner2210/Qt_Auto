
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


