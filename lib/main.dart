import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // กัปตันตรวจสอบ URL และ Anon Key ของกัปตันอีกครั้งนะครับ
  await Supabase.initialize(
    url: 'https://jeyqocnwodwkempuzriv.supabase.co/rest/v1/',
    anonKey: 'sb_publishable_HXdNPamCPOEhvXcoYeJ6Xw_8I7hdFjF',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'จักรพงษ์ POS',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // 1. ดึงข้อมูลที่รวมฟิลด์ parent_id มาด้วย
  Future<void> fetchProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select(
            'product_id, product_name, price_per_unit, quantity, parent_id, unit_call',
          )
          .order('product_name', ascending: true);

      setState(() {
        products = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // 2. Logic ตัดสต็อกที่ถังแม่ (Parent ID)
  Future<void> handleSale(Map<String, dynamic> item) async {
    // ถ้ามี parent_id ให้ไปตัดที่ ID นั้น ถ้าไม่มีให้ตัดที่ตัวเอง
    final String targetId =
        (item['parent_id'] != null && item['parent_id'].toString().isNotEmpty)
        ? item['parent_id'].toString()
        : item['product_id'].toString();

    try {
      // เช็คจำนวนล่าสุดจากเป้าหมาย
      final response = await supabase
          .from('products')
          .select('quantity, product_name')
          .eq('product_id', targetId)
          .single();

      final int currentQty = (response['quantity'] as num).toInt();
      final String targetName = response['product_name'];

      if (currentQty > 0) {
        await supabase
            .from('products')
            .update({'quantity': currentQty - 1})
            .eq('product_id', targetId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ขายสำเร็จ! $targetName เหลือ ${currentQty - 1} ${item['unit_call'] ?? ''}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
          fetchProducts(); // รีเฟรชยอดหลังขาย
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ขออภัย: $targetName หมดแล้ว!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PoPoSoy IT Stock - ระบบจัดการสต็อก')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                // ซ่อนตัว 'ถังแม่' ไม่ให้โชว์เป็นปุ่มขาย (ถ้ากัปตันต้องการ)
                // หรือจะโชว์ไว้ดูสต็อกเฉยๆ ก็ได้ครับ
                return ListTile(
                  title: Text(item['product_name']),
                  subtitle: Text(
                    'ราคา: ${item['price_per_unit']} บาท | คงเหลือ: ${item['quantity']}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => handleSale(item),
                    child: const Text('ขาย'),
                  ),
                );
              },
            ),
    );
  }
}
