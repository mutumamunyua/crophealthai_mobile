// lib/screens/professional_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ProfessionalRegistrationScreen extends StatefulWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  State<ProfessionalRegistrationScreen> createState() =>
      _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState
    extends State<ProfessionalRegistrationScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Professional Registration'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.blueGrey.shade50,
              child: TabBar(
                indicatorColor: Colors.teal,
                indicatorWeight: 3.0,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: 'AGROVET'),
                  Tab(text: 'EXTENSION WORKER'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _AgrovetForm(),
            _ExtensionWorkerForm(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AGROVET REGISTRATION FORM
// -----------------------------------------------------------------------------
class _AgrovetForm extends StatefulWidget {
  const _AgrovetForm();

  @override
  State<_AgrovetForm> createState() => _AgrovetFormState();
}

class _AgrovetFormState extends State<_AgrovetForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  List<String> _counties = [];
  List<String> _towns = [];
  String? _selectedCounty;
  String? _selectedTown;

  bool _isLoadingCounties = true;
  bool _isLoadingTowns = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCounties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _fetchCounties() async {
    try {
      final uri = Uri.parse('$backendBaseURL/geolocation/counties');
      final response = await http.get(uri);
      if (mounted && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _counties = data.cast<String>()..sort();
          _isLoadingCounties = false;
        });
      } else if (mounted) {
        throw Exception('Failed to load counties');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCounties = false);
        _showErrorSnackBar('Could not fetch counties. Please try again.');
      }
    }
  }

  Future<void> _fetchTowns(String county) async {
    setState(() {
      _isLoadingTowns = true;
      _towns = [];
      _selectedTown = null;
    });
    try {
      final uri = Uri.parse('$backendBaseURL/geolocation/towns/$county');
      final response = await http.get(uri);
      if (mounted && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _towns = data.cast<String>()..sort();
          _isLoadingTowns = false;
        });
      } else if (mounted) {
        throw Exception('Failed to load towns');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTowns = false);
        _showErrorSnackBar('Could not fetch towns for $county.');
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('$backendBaseURL/register/agrovet');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'contact': _contactController.text,
          'county': _selectedCounty,
          'town': _selectedTown,
        }),
      );

      if (mounted && response.statusCode == 201) {
        _showSuccessSnackBar('Agrovet registered successfully!');
        _formKey.currentState!.reset();
        setState(() {
          _selectedCounty = null;
          _selectedTown = null;
          _towns = [];
        });
      } else if (mounted) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to register');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Agrovet Name'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCounty,
              decoration: InputDecoration(
                labelText: 'County',
                prefixIcon:
                _isLoadingCounties ? const CircularProgressIndicator() : null,
              ),
              items: _counties.map((county) {
                return DropdownMenuItem(value: county, child: Text(county));
              }).toList(),
              onChanged: _isLoadingCounties
                  ? null
                  : (value) {
                if (value != null) {
                  setState(() => _selectedCounty = value);
                  _fetchTowns(value);
                }
              },
              validator: (value) =>
              value == null ? 'Please select a county' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTown,
              decoration: InputDecoration(
                labelText: 'Town',
                prefixIcon:
                _isLoadingTowns ? const CircularProgressIndicator() : null,
              ),
              items: _towns.map((town) {
                return DropdownMenuItem(value: town, child: Text(town));
              }).toList(),
              onChanged: (_selectedCounty == null || _isLoadingTowns)
                  ? null
                  : (value) {
                setState(() => _selectedTown = value);
              },
              validator: (value) =>
              value == null ? 'Please select a town' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Phone Contact'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
              value!.isEmpty ? 'Please enter a contact' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('REGISTER AGROVET'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EXTENSION WORKER REGISTRATION FORM
// -----------------------------------------------------------------------------
class _ExtensionWorkerForm extends StatefulWidget {
  const _ExtensionWorkerForm();

  @override
  State<_ExtensionWorkerForm> createState() => _ExtensionWorkerFormState();
}

class _ExtensionWorkerFormState extends State<_ExtensionWorkerForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _servicesController = TextEditingController();
  final _contactController = TextEditingController();

  List<String> _counties = [];
  List<String> _towns = [];
  String? _selectedCounty;
  String? _selectedTown;

  bool _isLoadingCounties = true;
  bool _isLoadingTowns = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCounties();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _servicesController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _fetchCounties() async {
    try {
      final uri = Uri.parse('$backendBaseURL/geolocation/counties');
      final response = await http.get(uri);
      if (mounted && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _counties = data.cast<String>()..sort();
          _isLoadingCounties = false;
        });
      } else if (mounted) {
        throw Exception('Failed to load counties');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCounties = false);
        _showErrorSnackBar('Could not fetch counties. Please try again.');
      }
    }
  }

  Future<void> _fetchTowns(String county) async {
    setState(() {
      _isLoadingTowns = true;
      _towns = [];
      _selectedTown = null;
    });
    try {
      final uri = Uri.parse('$backendBaseURL/geolocation/towns/$county');
      final response = await http.get(uri);
      if (mounted && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _towns = data.cast<String>()..sort();
          _isLoadingTowns = false;
        });
      } else if (mounted) {
        throw Exception('Failed to load towns');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTowns = false);
        _showErrorSnackBar('Could not fetch towns for $county.');
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('$backendBaseURL/register/extension-worker');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'contact': _contactController.text,
          'services':
          _servicesController.text.split(',').map((s) => s.trim()).toList(),
          'county': _selectedCounty,
          'town': _selectedTown,
        }),
      );

      if (mounted && response.statusCode == 201) {
        _showSuccessSnackBar('Extension Worker registered successfully!');
        _formKey.currentState!.reset();
        setState(() {
          _selectedCounty = null;
          _selectedTown = null;
          _towns = [];
        });
      } else if (mounted) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to register');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter a first name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter a last name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCounty,
              decoration: InputDecoration(
                labelText: 'County',
                prefixIcon:
                _isLoadingCounties ? const CircularProgressIndicator() : null,
              ),
              items: _counties.map((county) {
                return DropdownMenuItem(value: county, child: Text(county));
              }).toList(),
              onChanged: _isLoadingCounties
                  ? null
                  : (value) {
                if (value != null) {
                  setState(() => _selectedCounty = value);
                  _fetchTowns(value);
                }
              },
              validator: (value) =>
              value == null ? 'Please select a county' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTown,
              decoration: InputDecoration(
                labelText: 'Town',
                prefixIcon:
                _isLoadingTowns ? const CircularProgressIndicator() : null,
              ),
              items: _towns.map((town) {
                return DropdownMenuItem(value: town, child: Text(town));
              }).toList(),
              onChanged: (_selectedCounty == null || _isLoadingTowns)
                  ? null
                  : (value) {
                setState(() => _selectedTown = value);
              },
              validator: (value) =>
              value == null ? 'Please select a town' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _servicesController,
              decoration: const InputDecoration(
                  labelText: 'Services',
                  hintText: 'e.g. soil testing, pest control'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter services' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Phone Contact'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
              value!.isEmpty ? 'Please enter a contact' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('REGISTER EXTENSION WORKER'),
            ),
          ],
        ),
      ),
    );
  }
}