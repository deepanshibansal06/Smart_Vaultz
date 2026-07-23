import '../models/vault_model.dart';

class AILockerAllocationResult {
  final VaultModel vault;
  final int matchPercentage;
  final List<String> reasons;

  AILockerAllocationResult({
    required this.vault,
    required this.matchPercentage,
    required this.reasons,
  });
}

/// AI-Based Locker Allocation Engine
/// Optimizes locker selection according to:
/// 1. Small parcels → Small lockers (Space optimization)
/// 2. Heavy parcels → Lower/Ground lockers (Ergonomic safety)
/// 3. Priority deliveries → Closest entrance lockers (Accessibility speed)
class AILockerAllocationService {
  static AILockerAllocationResult? findOptimalLocker({
    required List<VaultModel> lockers,
    required String parcelSize, // 'small' | 'medium' | 'large'
    required bool isHeavy, // true for ≥ 5kg
    required bool isExpressPriority, // true for High Priority Express
  }) {
    final available = lockers.where((l) => l.status == 'available').toList();
    if (available.isEmpty) return null;

    AILockerAllocationResult? bestResult;
    int maxScore = -999;

    for (final locker in available) {
      int score = 0;
      final List<String> reasons = [];

      final lockerSize = locker.size.isEmpty
          ? (locker.price <= 150 ? 'small' : locker.price <= 250 ? 'medium' : 'large')
          : locker.size;
      final isLowerLevel = locker.level == 'lower' ||
          locker.location.toLowerCase().contains('ground') ||
          locker.location.toLowerCase().contains('entrance');
      final isClosest = locker.proximity == 'closest' ||
          locker.location.toLowerCase().contains('entrance') ||
          locker.location.toLowerCase().contains('building a');

      // 1. Size Matching
      if (parcelSize == 'small') {
        if (lockerSize == 'small') {
          score += 40;
          reasons.add('Exact Small size fit (0% space waste)');
        } else if (lockerSize == 'medium') {
          score += 20;
          reasons.add('Medium locker fit for small parcel');
        } else {
          score += 5;
          reasons.add('Large locker (higher space waste)');
        }
      } else if (parcelSize == 'medium') {
        if (lockerSize == 'medium') {
          score += 40;
          reasons.add('Exact Medium size fit');
        } else if (lockerSize == 'large') {
          score += 25;
          reasons.add('Large locker fit for medium parcel');
        } else {
          score -= 100;
        }
      } else if (parcelSize == 'large') {
        if (lockerSize == 'large') {
          score += 40;
          reasons.add('Exact Large size fit');
        } else {
          score -= 100;
        }
      }

      // 2. Ergonomic Weight Optimization
      if (isHeavy) {
        if (isLowerLevel) {
          score += 35;
          reasons.add('Ground/Lower level assigned for heavy parcel safety (≥5kg)');
        } else {
          score -= 25;
          reasons.add('Upper rack requires overhead lifting');
        }
      } else {
        score += 20;
      }

      // 3. Priority Accessibility
      if (isExpressPriority) {
        if (isClosest) {
          score += 25;
          reasons.add('Closest entrance location prioritized for Express priority delivery');
        } else {
          score += 5;
        }
      } else {
        if (isClosest) {
          score += 15;
        } else {
          score += 10;
        }
      }

      final matchPercentage = (score.clamp(15, 100) * 0.99).round();

      if (score > maxScore) {
        maxScore = score;
        bestResult = AILockerAllocationResult(
          vault: locker,
          matchPercentage: matchPercentage,
          reasons: reasons,
        );
      }
    }

    return bestResult;
  }
}
