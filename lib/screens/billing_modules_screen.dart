import 'package:flutter/material.dart';
import '../models/billing.dart';
import '../services/billing_service.dart';

class BillingModulesScreen extends StatefulWidget {
  const BillingModulesScreen({super.key});
  @override
  State<BillingModulesScreen> createState() => _BillingModulesScreenState();
}

class _BillingModulesScreenState extends State<BillingModulesScreen> {
  final service = BillingService();
  late Future<List<BillingModule>> future;
  @override
  void initState() { super.initState(); future = service.modules(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product Catalogue')),
    body: FutureBuilder<List<BillingModule>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!.where((p) => p.active).toList()
          ..sort((a,b) => a.displayOrder.compareTo(b.displayOrder));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: ['CORE','MODULE','ADD_ON'].expand((type) {
            final items = products.where((p) => p.productType == type).toList();
            if (items.isEmpty) return <Widget>[];
            final title = type == 'ADD_ON' ? 'Add-ons' : type == 'CORE' ? 'MAWA Core' : 'Business Modules';
            return <Widget>[
              Padding(padding: const EdgeInsets.fromLTRB(4,16,4,8), child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              ...items.map((m) => Card(child: ListTile(
                leading: Icon(type == 'ADD_ON' ? Icons.extension : type == 'CORE' ? Icons.hub : Icons.apps),
                title: Text(m.name),
                subtitle: Text([m.description ?? '', if (m.requiredModuleCode != null) 'Requires: ${m.requiredModuleCode}'].where((e) => e.isNotEmpty).join('\n')),
                trailing: Text(m.code),
              ))),
            ];
          }).toList(),
        );
      },
    ),
  );
}
