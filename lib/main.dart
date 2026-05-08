import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // กัปตันตรวจสอบ URL และ Key จากหน้า Settings > API ใน Supabase นะครับ
  await Supabase.initialize(
    url: 'https://jeyqocnwodwkempuzriv.supabase.co/rest/v1/',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpleXFvY253b2R3a2VtcHV6cml2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NzA4NzEsImV4cCI6MjA5MzA0Njg3MX0.a_dvT5-4xmQP61EsXGxbMNRCSMJ3x8xWIPJ5ivvYap8',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบสต็อกสินค้า',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const AddStockPage(),
    );
  }
}

class AddStockPage extends StatefulWidget {
  const AddStockPage({super.key});

  @override
  State<AddStockPage> createState() => _AddStockPageState();
}

class _AddStockPageState extends State<AddStockPage> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveToStock() async {
    final name = _nameController.text.trim();
    final qtyText = _qtyController.text.trim();
    final qty = int.tryParse(qtyText) ?? 0;

    if (name.isEmpty) {
      _showSnackBar('กรุณาระบุชื่อสินค้า');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ส่งข้อมูลไปที่ตาราง products ใน Supabase
      await supabase.from('products').insert({
        'product_name': name,
        'quantity': qty,
      });

      if (!mounted) return;
      _showSnackBar('บันทึก "$name" เรียบร้อยแล้ว');
      _nameController.clear();
      _qtyController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มสินค้าเข้าสต็อก')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(
                labelText: 'จำนวน',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveToStock,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
