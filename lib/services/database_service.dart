import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CarSpot {
  final String? id;
  final String brand;
  final String model;
  final String year;
  final String? imageUrl;
  final String date;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarSpot({
    this.id,
    required this.brand,
    required this.model,
    required this.year,
    this.imageUrl,
    required this.date,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'image_url': imageUrl,
      'date': date,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CarSpot.fromJson(Map<String, dynamic> json) {
    return CarSpot(
      id: json['id'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      imageUrl: json['image_url'],
      date: json['date'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class DatabaseService {
  final SupabaseService _supabase = SupabaseService.instance;
  
  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'car-spots/${_supabase.currentUser!.id}/$fileName';
      
      await _supabase.client.storage
          .from('car-spots')
          .uploadBinary(filePath, await imageFile.readAsBytes());
      
      final publicUrl = _supabase.client.storage
          .from('car-spots')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }
  
  Future<CarSpot> createCarSpot({
    required String brand,
    required String model,
    required String year,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }
      
      final carSpot = CarSpot(
        brand: brand,
        model: model,
        year: year,
        imageUrl: imageUrl,
        date: DateTime.now().toIso8601String().split('T')[0],
        userId: _supabase.currentUser!.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final response = await _supabase.client
          .from('car_spots')
          .insert(carSpot.toJson())
          .select()
          .single();
      
      return CarSpot.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create car spot: ${e.toString()}');
    }
  }
  
  Future<List<CarSpot>> getCarSpots() async {
    try {
      final response = await _supabase.client
          .from('car_spots')
          .select()
          .eq('user_id', _supabase.currentUser!.id)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => CarSpot.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch car spots: ${e.toString()}');
    }
  }
  
  Future<CarSpot> updateCarSpot({
    required String id,
    String? brand,
    String? model,
    String? year,
    File? imageFile,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (brand != null) updates['brand'] = brand;
      if (model != null) updates['model'] = model;
      if (year != null) updates['year'] = year;
      
      if (imageFile != null) {
        updates['image_url'] = await uploadImage(imageFile);
      }
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase.client
          .from('car_spots')
          .update(updates)
          .eq('id', id)
          .eq('user_id', _supabase.currentUser!.id)
          .select()
          .single();
      
      return CarSpot.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update car spot: ${e.toString()}');
    }
  }
  
  Future<void> deleteCarSpot(String id) async {
    try {
      await _supabase.client
          .from('car_spots')
          .delete()
          .eq('id', id)
          .eq('user_id', _supabase.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete car spot: ${e.toString()}');
    }
  }
  
  Future<List<String>> getBrands() async {
    try {
      final response = await _supabase.client
          .from('car_spots')
          .select('brand')
          .eq('user_id', _supabase.currentUser!.id);
      
      final brands = (response as List)
          .map((json) => json['brand'] as String)
          .toSet()
          .toList();
      
      return brands;
    } catch (e) {
      throw Exception('Failed to fetch brands: ${e.toString()}');
    }
  }
  
  Future<int> getCarSpotCount() async {
    try {
      final response = await _supabase.client
          .from('car_spots')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', _supabase.currentUser!.id);
      
      return response.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get car spot count: ${e.toString()}');
    }
  }
}
