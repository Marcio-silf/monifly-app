import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/wishlist_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class WishlistNotifier extends StateNotifier<List<WishlistItem>> {
  final SupabaseClient _supabase;

  WishlistNotifier(this._supabase) : super([]) {
    _init();
  }

  Future<void> _init() async {
    _loadFromCache();
    await _syncWithCloud();
  }

  void _loadFromCache() {
    final box = Hive.box('metadata');
    final cached = box.get('wishlist_items');
    if (cached != null) {
      try {
        final List decoded = json.decode(cached);
        state = decoded.map((e) => WishlistItem.fromJson(e)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  void _saveToCache() {
    final box = Hive.box('metadata');
    final encoded = json.encode(state.map((e) => e.toJson()).toList());
    box.put('wishlist_items', encoded);
  }

  Future<void> _syncWithCloud() async {
    try {
      if (_supabase.auth.currentUser == null) return;
      
      final response = await _supabase.from('wishlist_items').select();
      final items = response.map((e) => WishlistItem.fromJson(e)).toList();
      state = items;
      _saveToCache();
    } catch (e) {
      // Silently fail, retaining cache
    }
  }

  void addWish(String userId, String name, double value, String category) async {
    final now = DateTime.now();
    final item = WishlistItem(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      value: value,
      category: category,
      registeredAt: now,
      releaseAt: now.add(const Duration(days: 30)),
    );
    state = [...state, item];
    _saveToCache();
    
    try {
      await _supabase.from('wishlist_items').insert(item.toJson());
    } catch (e) {
      // Silently fail, retaining cache
    }
  }

  void finalizeWish(String id, bool bought) async {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(status: bought ? 'bought' : 'discarded')
        else
          item
    ];
    _saveToCache();
    
    try {
      await _supabase.from('wishlist_items').update({
        'status': bought ? 'bought' : 'discarded'
      }).eq('id', id);
    } catch (e) {
      // Silently fail, retaining cache
    }
  }

  void deleteWish(String id) async {
    state = state.where((item) => item.id != id).toList();
    _saveToCache();
    
    try {
      await _supabase.from('wishlist_items').delete().eq('id', id);
    } catch (e) {
      // Silently fail, retaining cache
    }
  }

  Map<String, dynamic> calculateStats() {
    double totalDesired = 0;
    double saved = 0;
    double spent = 0;
    int boughtCount = 0;
    int discardedCount = 0;
    int observingCount = 0;

    for (var item in state) {
      totalDesired += item.value;
      if (item.status == 'bought') {
        spent += item.value;
        boughtCount++;
      } else if (item.status == 'discarded') {
        saved += item.value;
        discardedCount++;
      } else {
        observingCount++;
      }
    }

    int totalDecided = boughtCount + discardedCount;
    double successRate = totalDecided > 0 ? (discardedCount / totalDecided) * 100 : 0;

    return {
      'totalDesired': totalDesired,
      'saved': saved,
      'spent': spent,
      'observingCount': observingCount,
      'successRate': successRate,
    };
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<WishlistItem>>((ref) {
  return WishlistNotifier(Supabase.instance.client);
});
