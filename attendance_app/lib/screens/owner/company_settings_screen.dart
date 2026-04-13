import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  static const Duration _requestTimeout = Duration(seconds: 12);

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();

  bool _isLoading = false;
  bool _isSaving = false;
  UserModel? _user;
  CompanyModel? _company;
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (mounted) {
          setState(() {
            _user = userData;
          });
        }

        if (userData?.companyId != null) {
          final company = await _firestoreService.getCompany(
            userData!.companyId!,
          ).timeout(_requestTimeout);

          if (company != null) {
            _companyNameController.text = company.name;
            _addressController.text = company.address ?? '';
            _radiusController.text = company.radiusInMeters.toString();
            _startTimeController.text = company.workingStartTime ?? '09:00';
            _endTimeController.text = company.workingEndTime ?? '18:00';

            setState(() {
              _company = company;
            });
          }
        }
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        final apiDisabled = e.code == 'permission-denied' &&
            (e.message ?? '').toLowerCase().contains('firestore api');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiDisabled
                  ? 'Cloud Firestore API is disabled for this project. Enable it in Google Cloud Console, then retry.'
                  : 'Error loading company: ${e.message ?? e.code}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading timed out. Please check internet and retry.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading company: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationInfo = await _locationService.getLocationInfo();
      if (locationInfo != null) {
        final latitude = locationInfo['latitude'];
        final longitude = locationInfo['longitude'];
        if (latitude == null || longitude == null) {
          throw StateError('Location data is incomplete.');
        }

        setState(() {
          _currentLatitude = latitude;
          _currentLongitude = longitude;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get location'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveCompany() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_currentLatitude == null || _currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get current location first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Check if user is logged in
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: user profile not loaded. Please reopen screen.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = _user;
      if (currentUser == null) {
        throw StateError('User profile missing while saving company.');
      }

      if (_company != null) {
        // Update existing company
        final updatedCompany = _company!.copyWith(
          name: _companyNameController.text.trim(),
          address: _addressController.text.trim(),
          latitude: _currentLatitude,
          longitude: _currentLongitude,
          radiusInMeters: double.tryParse(_radiusController.text) ?? 100.0,
          workingStartTime: _startTimeController.text,
          workingEndTime: _endTimeController.text,
        );

        await _firestoreService
            .updateCompany(updatedCompany)
            .timeout(_requestTimeout);
      } else {
        // Create new company - use Firebase generated ID instead of relying on user's companyId
        // This fixes the null check operator error when user doesn't have a companyId yet
        final companyDocRef = _firestoreService.createCompanyDoc();
        final newCompany = CompanyModel(
          id: companyDocRef.id,
          name: _companyNameController.text.trim(),
          ownerId: currentUser.id,
          address: _addressController.text.trim(),
          latitude: _currentLatitude,
          longitude: _currentLongitude,
          radiusInMeters: double.tryParse(_radiusController.text) ?? 100.0,
          workingStartTime: _startTimeController.text,
          workingEndTime: _endTimeController.text,
          createdAt: DateTime.now(),
        );

        await _firestoreService
            .createCompany(newCompany)
            .timeout(_requestTimeout);

        // Update user's companyId after company is created
        final updatedUser = currentUser.copyWith(companyId: companyDocRef.id);
        await _authService.updateUserData(updatedUser).timeout(_requestTimeout);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company settings saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        final apiDisabled = e.code == 'permission-denied' &&
            (e.message ?? '').toLowerCase().contains('firestore api');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiDisabled
                  ? 'Cloud Firestore API is disabled for this project. Enable it in Google Cloud Console, wait a few minutes, then try again.'
                  : 'Error saving company: ${e.message ?? e.code}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save timed out. Please check internet and try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving company: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Company Name
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company Location',
                              style: AppTheme.headingSmall,
                            ),
                            const SizedBox(height: 8),
                            if (_currentLatitude != null &&
                                _currentLongitude != null)
                              Text(
                                'Lat: ${_currentLatitude!.toStringAsFixed(6)}, Lng: ${_currentLongitude!.toStringAsFixed(6)}',
                                style: AppTheme.bodyMedium,
                              )
                            else
                              Text(
                                'Location not set',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Get Current Location'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Radius
                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Radius (meters)',
                        prefixIcon: Icon(Icons.radar),
                        helperText:
                            'Attendance will be valid within this radius',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter radius';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Working Hours
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveCompany,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
