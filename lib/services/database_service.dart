import 'dart:io';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class CarSpot {
  final String? id;
  final String? spotterId;
  final String? locationId;
  final String brand;
  final String model;
  final int? year;
  final String? color;
  final String? licensePlate;
  final String? description;
  final List<String> imageUrls;
  final String visibility;
  final bool isVerified;
  final String? verifiedBy;
  final int likesCount;
  final int commentsCount;
  final int rarityScore;
  final String? weatherConditions;
  final DateTime spottedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarSpot({
    this.id,
    this.spotterId,
    this.locationId,
    required this.brand,
    required this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.description,
    this.imageUrls = const [],
    this.visibility = 'public',
    this.isVerified = false,
    this.verifiedBy,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.rarityScore = 1,
    this.weatherConditions,
    required this.spottedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'spotter_id': spotterId,
      'location_id': locationId,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'description': description,
      'image_urls': imageUrls,
      'visibility': visibility,
      'is_verified': isVerified,
      'verified_by': verifiedBy,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'rarity_score': rarityScore,
      'weather_conditions': weatherConditions,
      'spotted_at': spottedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not null (for updates)
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory CarSpot.fromJson(Map<String, dynamic> json) {
    return CarSpot(
      id: json['id'],
      spotterId: json['spotter_id'],
      locationId: json['location_id'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      color: json['color'],
      licensePlate: json['license_plate'],
      description: json['description'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      visibility: json['visibility'] ?? 'public',
      isVerified: json['is_verified'] ?? false,
      verifiedBy: json['verified_by'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      rarityScore: json['rarity_score'] ?? 1,
      weatherConditions: json['weather_conditions'],
      spottedAt: DateTime.parse(json['spotted_at']),
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
      final filePath = 'car-images/${_supabase.currentUser!.id}/$fileName';
      
      await _supabase.client.storage
          .from('car-images')
          .uploadBinary(filePath, await imageFile.readAsBytes());
      
      final publicUrl = _supabase.client.storage
          .from('car-images')
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
      // Try different brand formats to find what works
      String finalBrand = brand;
      
      // Try the brand as-is first
      try {
        List<String> imageUrls = [];
        if (imageFile != null) {
          final imageUrl = await uploadImage(imageFile);
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
        
        final carSpot = CarSpot(
          id: null, // Let database generate UUID
          spotterId: _supabase.currentUser!.id,
          brand: finalBrand,
          model: model,
          year: int.tryParse(year),
          imageUrls: imageUrls,
          spottedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final response = await _supabase.client
            .from('car_spots')
            .insert(carSpot.toJson())
            .select()
            .single();
        
        final createdSpot = CarSpot.fromJson(response);
        
        // Create related records
        await _createRelatedRecords(createdSpot);
        
        return createdSpot;
      } catch (e) {
        debugPrint('DatabaseService: Brand $finalBrand failed, trying alternatives: $e');
        
        // Try alternative formats
        final alternatives = [
          brand.toUpperCase(),
          brand.toLowerCase(),
          brand.replaceAll('_', ' '),
          brand.replaceAll(' ', '_'),
        ];
        
        for (String altBrand in alternatives) {
          if (altBrand == finalBrand) continue;
          
          try {
            List<String> imageUrls = [];
            if (imageFile != null) {
              final imageUrl = await uploadImage(imageFile);
              if (imageUrl != null) {
                imageUrls.add(imageUrl);
              }
            }
            
            final carSpot = CarSpot(
              id: null, // Let database generate UUID
              spotterId: _supabase.currentUser!.id,
              brand: altBrand,
              model: model,
              year: int.tryParse(year),
              imageUrls: imageUrls,
              spottedAt: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            final response = await _supabase.client
                .from('car_spots')
                .insert(carSpot.toJson())
                .select()
                .single();
            
            final createdSpot = CarSpot.fromJson(response);
            
            // Create related records
            await _createRelatedRecords(createdSpot);
            
            debugPrint('DatabaseService: Successfully used brand: $altBrand');
            return createdSpot;
          } catch (altError) {
            debugPrint('DatabaseService: Brand $altBrand also failed: $altError');
            continue;
          }
        }
        
        // If all alternatives failed, throw the original error
        rethrow;
      }
    } catch (e) {
      throw Exception('Failed to create car spot: ${e.toString()}');
    }
  }
  
  Future<List<CarSpot>> getCarSpots() async {
    try {
      debugPrint('DatabaseService: Fetching car spots for user ${_supabase.currentUser!.id}');
      final response = await _supabase.client
          .from('car_spots')
          .select()
          .eq('spotter_id', _supabase.currentUser!.id)
          .order('created_at', ascending: false);
      
      debugPrint('DatabaseService: Received ${(response as List).length} car spots');
      return (response as List)
          .map((json) => CarSpot.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('DatabaseService: Error fetching car spots: $e');
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
        updates['image_urls'] = await uploadImage(imageFile);
      }
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase.client
          .from('car_spots')
          .update(updates)
          .eq('id', id)
          .eq('spotter_id', _supabase.currentUser!.id)
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
          .eq('spotter_id', _supabase.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete car spot: ${e.toString()}');
    }
  }
  
  Future<List<String>> getBrands() async {
    try {
      final response = await _supabase.client
          .from('car_spots')
          .select('brand')
          .eq('spotter_id', _supabase.currentUser!.id);
      
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
          .select('id')
          .eq('spotter_id', _supabase.currentUser!.id);
      
      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get car spot count: ${e.toString()}');
    }
  }
  
  Future<List<String>> getValidBrands() async {
    try {
      // Try to get the enum values by querying the information_schema
      final response = await _supabase.client
          .rpc('get_enum_values', params: {'enum_name': 'car_brand'});
      
      if (response != null && response is List) {
        return response.cast<String>();
      }
      
      // Fallback: try some common brand names
      return ['BMW', 'AUDI', 'MERCEDES', 'FERRARI', 'PORSCHE'];
    } catch (e) {
      debugPrint('DatabaseService: Error getting valid brands: $e');
      // Return a minimal set of likely valid brands
      return ['BMW', 'AUDI', 'MERCEDES'];
    }
  }

  Future<String?> createLocation({
    required String name,
    required String address,
    required String city,
    required String country,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final locationData = {
        'name': name,
        'address': address,
        'city': city,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'is_popular_spot': false,
        'total_spots': 1,
      };
      
      final response = await _supabase.client
          .from('locations')
          .insert(locationData)
          .select('id')
          .single();
      
      return response['id'];
    } catch (e) {
      debugPrint('DatabaseService: Error creating location: $e');
      return null;
    }
  }

  Future<String?> createUserCollection({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final collectionData = {
        'user_id': _supabase.currentUser!.id,
        'name': name,
        'description': description,
        'is_public': isPublic,
        'spots_count': 0,
      };
      
      final response = await _supabase.client
          .from('user_collections')
          .insert(collectionData)
          .select('id')
          .single();
      
      return response['id'];
    } catch (e) {
      debugPrint('DatabaseService: Error creating user collection: $e');
      return null;
    }
  }

  Future<void> addSpotToCollection({
    required String collectionId,
    required String spotId,
  }) async {
    try {
      final collectionSpotData = {
        'collection_id': collectionId,
        'spot_id': spotId,
      };
      
      await _supabase.client
          .from('collection_spots')
          .insert(collectionSpotData);
      
      // Update collection spots count
      final spotsCount = await _getCollectionSpotsCount(collectionId);
      await _supabase.client
          .from('user_collections')
          .update({'spots_count': spotsCount})
          .eq('id', collectionId);
      
      debugPrint('DatabaseService: Updated collection $collectionId with $spotsCount spots');
    } catch (e) {
      debugPrint('DatabaseService: Error adding spot to collection: $e');
    }
  }

  Future<int> _getCollectionSpotsCount(String collectionId) async {
    try {
      final response = await _supabase.client
          .from('collection_spots')
          .select('id')
          .eq('collection_id', collectionId);
      
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _refreshCollectionCount(String collectionId) async {
    try {
      final spotsCount = await _getCollectionSpotsCount(collectionId);
      await _supabase.client
          .from('user_collections')
          .update({'spots_count': spotsCount})
          .eq('id', collectionId);
      
      debugPrint('DatabaseService: Refreshed collection $collectionId count to $spotsCount');
    } catch (e) {
      debugPrint('DatabaseService: Error refreshing collection count: $e');
    }
  }

  Future<void> createUserAchievement({
    required String achievementId,
    Map<String, dynamic>? progress,
  }) async {
    try {
      final achievementData = {
        'user_id': _supabase.currentUser!.id,
        'achievement_id': achievementId,
        'progress': progress ?? {},
      };
      
      await _supabase.client
          .from('user_achievements')
          .insert(achievementData);
      
      debugPrint('DatabaseService: Created achievement $achievementId for user');
    } catch (e) {
      debugPrint('DatabaseService: Error creating user achievement: $e');
    }
  }

  Future<void> checkAndCreateAchievements(int totalSpots) async {
    try {
      // Check for "First Spot" achievement
      if (totalSpots == 1) {
        await createUserAchievement(achievementId: 'first_spot');
      }
      
      // Check for "10 Spots" achievement
      if (totalSpots == 10) {
        await createUserAchievement(achievementId: 'ten_spots');
      }
      
      // Check for "50 Spots" achievement
      if (totalSpots == 50) {
        await createUserAchievement(achievementId: 'fifty_spots');
      }
      
      // Check for "100 Spots" achievement
      if (totalSpots == 100) {
        await createUserAchievement(achievementId: 'hundred_spots');
      }
      
    } catch (e) {
      debugPrint('DatabaseService: Error checking achievements: $e');
    }
  }

  Future<void> _createRelatedRecords(CarSpot carSpot) async {
    try {
      // 1. Create a default location (you can enhance this with actual GPS data later)
      final locationId = await createLocation(
        name: 'Unknown Location',
        address: 'Address not specified',
        city: 'Unknown City',
        country: 'Unknown Country',
        latitude: 0.0,
        longitude: 0.0,
        description: 'Location created automatically for car spot',
      );
      
      // Update the car spot with the location ID
      if (locationId != null && carSpot.id != null) {
        await _supabase.client
            .from('car_spots')
            .update({'location_id': locationId})
            .eq('id', carSpot.id!);
      }
      
      // 2. Create a default collection for this brand
      final collectionId = await createUserCollection(
        name: '${carSpot.brand.replaceAll('_', ' ')} Collection',
        description: 'My collection of ${carSpot.brand.replaceAll('_', ' ')} cars',
        isPublic: true,
      );
      
      // 3. Add the spot to the collection
      if (collectionId != null) {
        await addSpotToCollection(
          collectionId: collectionId,
          spotId: carSpot.id!,
        );
      }
      
      // 4. Check and create achievements
      final totalSpots = await getCarSpotCount();
      await checkAndCreateAchievements(totalSpots);
      
      // 5. Refresh collection count
      if (collectionId != null) {
        await _refreshCollectionCount(collectionId);
      }
      
      debugPrint('DatabaseService: Created related records for car spot ${carSpot.id}');
    } catch (e) {
      debugPrint('DatabaseService: Error creating related records: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _supabase.client
          .from('user_profiles')
          .select()
          .eq('id', _supabase.currentUser!.id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('DatabaseService: Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> createUserProfile({
    required String email,
    required String fullName,
  }) async {
    try {
      debugPrint('DatabaseService: Creating user profile for $email');
      
      final userProfile = {
        'id': _supabase.currentUser!.id,
        'email': email,
        'username': email.split('@')[0], // Use email prefix as username
        'full_name': fullName,
        'bio': 'Car enthusiast and spotter',
        'role': 'spotter',
        'total_spots': 0,
        'reputation_score': 0,
        'is_verified': false,
        'privacy_settings': {
          'spots_visibility': 'public',
          'profile_visibility': 'public'
        },
      };
      
      await _supabase.client
          .from('user_profiles')
          .insert(userProfile);
      
      debugPrint('DatabaseService: User profile created successfully');
    } catch (e) {
      debugPrint('DatabaseService: Error creating user profile: $e');
      // Don't throw error - profile might already exist
    }
  }

  Future<void> createDefaultData() async {
    try {
      debugPrint('DatabaseService: Creating default data for new user');
      
      // Check if user already has data
      final existingSpots = await getCarSpots();
      if (existingSpots.isNotEmpty) {
        debugPrint('DatabaseService: User already has data, skipping default creation');
        return;
      }
      
      debugPrint('DatabaseService: Skipping default data creation due to enum validation issues');
      // Skip creating default data for now until we know the correct enum values
      
    } catch (e) {
      debugPrint('DatabaseService: Error creating default data: $e');
      // Don't throw the error, just log it so the app doesn't crash
    }
  }

  Future<void> deleteCurrentUserData() async {
    try {
      final String userId = _supabase.currentUser!.id;

      // Delete user achievements
      try {
        await _supabase.client
            .from('user_achievements')
            .delete()
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting user_achievements: $e');
      }

      // Get user collection ids
      List<dynamic> collections = [];
      try {
        collections = await _supabase.client
            .from('user_collections')
            .select('id')
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error fetching user_collections: $e');
      }

      // Delete collection_spots for those collections
      try {
        final List<String> collectionIds = collections
            .map((c) => c['id'] as String)
            .toList();
        for (final cid in collectionIds) {
          await _supabase.client
              .from('collection_spots')
              .delete()
              .eq('collection_id', cid);
        }
      } catch (e) {
        debugPrint('DatabaseService: Error deleting collection_spots: $e');
      }

      // Delete user collections
      try {
        await _supabase.client
            .from('user_collections')
            .delete()
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting user_collections: $e');
      }

      // Delete car spots
      try {
        await _supabase.client
            .from('car_spots')
            .delete()
            .eq('spotter_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting car_spots: $e');
      }

      // Delete user profile
      try {
        await _supabase.client
            .from('user_profiles')
            .delete()
            .eq('id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting user_profiles: $e');
      }

      // Delete storage objects under car-images bucket at path {userId}
      try {
        final storage = _supabase.client.storage.from('car-images');
        final listResult = await storage.list(path: userId);
        if (listResult.isNotEmpty) {
          final paths = listResult.map((f) => '$userId/${f.name}').toList();
          await storage.remove(paths);
        }
      } catch (e) {
        debugPrint('DatabaseService: Error deleting storage files: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete user data: ${e.toString()}');
    }
  }
}
