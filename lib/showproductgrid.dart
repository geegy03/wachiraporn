import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Method หลักในการเริ่มต้น
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(221, 188, 51, 51)),
        useMaterial3: true,
      ),
      home: showproductgrid(),
    );
  }
}

class showproductgrid extends StatefulWidget {
  @override
  State<showproductgrid> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<showproductgrid> {
  DatabaseReference dbRef = FirebaseDatabase.instance.ref('products');
  List<Map<String, dynamic>> products = [];
  String? selectedCategory;
  TextEditingController _selectedOption = TextEditingController();

  // ฟังก์ชันในการดึงข้อมูลสินค้า
  Future<void> fetchProducts() async {
    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> loadedProducts = [];
        snapshot.children.forEach((child) {
          Map<String, dynamic> product = Map<String, dynamic>.from(child.value as Map);
          product['key'] = child.key;
          loadedProducts.add(product);
        });
        loadedProducts.sort((a, b) => a['price'].compareTo(b['price']));
        setState(() {
          products = loadedProducts;
        });
      } else {
        print("ไม่พบสินค้าในฐานข้อมูล");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูล: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ฟังก์ชันแสดง Dialog แก้ไขข้อมูลสินค้า
  void showEditProductDialog(Map<String, dynamic> product) {
    TextEditingController nameController = TextEditingController(text: product['name']);
    TextEditingController descriptionController = TextEditingController(text: product['description']);
    TextEditingController priceController = TextEditingController(text: product['price'].toString());
    TextEditingController quantityController = TextEditingController(text: product['quantity'].toString());
    TextEditingController productionDateController = TextEditingController(text: product['productionDate']);
    TextEditingController discountController = TextEditingController(text: product['discount'].toString());

    List<String> categories = ['Electronics', 'Clothing', 'Food', 'Books'];

    selectedCategory = product['category']; // ตั้งค่าประเภทสินค้าตามข้อมูลที่มีในฐานข้อมูล

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('แก้ไขข้อมูลสินค้า'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'รายละเอียด'),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'ราคา'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'จำนวน'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: productionDateController,
                  decoration: InputDecoration(labelText: 'วันที่ผลิต'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: 'ประเภทสินค้า'),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                TextField(
                  controller: discountController,
                  decoration: InputDecoration(labelText: 'ส่วนลด'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ปิด Dialog
              },
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Map<String, dynamic> updatedData = {
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'price': int.parse(priceController.text),
                  'category': selectedCategory,
                  'productionDate': productionDateController.text,
                  'quantity': int.parse(quantityController.text),
                  'discount': discountController.text,
                };

                dbRef.child(product['key']).update(updatedData).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ข้อมูลสินค้าได้รับการแก้ไขเรียบร้อยแล้ว')));
                  fetchProducts(); // ดึงข้อมูลสินค้าใหม่มาแสดง
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
                });

                Navigator.of(dialogContext).pop(); // ปิด Dialog
              },
              child: Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันที่ใช้ในตอนเริ่มต้นเพื่อดึงข้อมูล
  @override
  void initState() {
    super.initState();
    fetchProducts(); // ดึงข้อมูลสินค้าเมื่อเปิดแอป
  }

  // ฟังก์ชันในการแสดงวันที่ในรูปแบบ dd/MM/yyyy
  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  // ฟังก์ชันลบสินค้า
  void deleteProduct(String key, BuildContext context) {
    dbRef.child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบสินค้าเรียบร้อยแล้ว')));
      fetchProducts(); // อัพเดตข้อมูลหลังการลบ
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    });
  }

  // ฟังก์ชันยืนยันการลบ
  void showDeleteConfirmationDialog(String key, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('ยืนยันการลบ'),
          content: Text('คุณแน่ใจว่าต้องการลบสินค้านี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('ไม่ลบ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                deleteProduct(key, context);
              },
              child: Text('ลบ', style: TextStyle(color: const Color.fromARGB(255, 211, 0, 0))),
            ),
          ],
        );
      },
    );
  }

  // ส่วนของการแสดง UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายการสินค้า',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 212, 92, 0),
      ),
      body: Stack(
        children: [
          // เพิ่มภาพพื้นหลัง
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          products.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () {},
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                SizedBox(height: 20),
                                Text(
                                  product['name'],
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'ราคา: ${product['price']} บาท',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    icon: Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () {
                                      showDeleteConfirmationDialog(product['key'], context);
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    icon: Icon(Icons.edit),
                                    color: Colors.blue,
                                    onPressed: () {
                                      showEditProductDialog(product);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
