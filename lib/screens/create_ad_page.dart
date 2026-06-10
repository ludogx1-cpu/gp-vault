import 'package:flutter/material.dart';

// Since this is a sub-page, we import your main file so we can use your custom header!
import '../widgets/widgets.dart';

// ==========================================
// 🚀 CREATE AD CAMPAIGN PAGE
// ==========================================
class CreateAdPage extends StatefulWidget {
  const CreateAdPage({super.key});

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🚀 Automatically uses your Dropdown Wallet header!
      appBar: const GlobalAppBar(
        showBackArrow: true, 
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.rocket_launch, size: 60, color: Colors.orange),
              const SizedBox(height: 15),
              const Text("Setup Your Ad Campaign", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 10),
              const Text("Fill out the details below to submit your custom banner or PTC link to the network.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Campaign Title", 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.title, color: Colors.orange)
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: "Target Link (URL)", 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.link, color: Colors.orange)
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter your destination URL';
                  if (!value.startsWith('http')) return 'URL must start with http:// or https://';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _imgCtrl,
                decoration: const InputDecoration(
                  labelText: "Banner Image URL (Optional for PTC)", 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.image, color: Colors.orange)
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("PROCEED TO AD STORE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                        // The user saves the draft and returns to the Ad Hub to buy the slot
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Campaign Draft Saved! Select an Ad Slot to purchase."), 
                          backgroundColor: Colors.green
                        ));
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}