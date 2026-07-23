class VaultModel {
  final String id;
  final String lockerNo;
  final String location;
  final double price;
  final String slotDate;
  final String timeSlot;
  final String status; // 'available' | 'booked'
  final String size; // 'small' | 'medium' | 'large'
  final String level; // 'lower' | 'upper'
  final String proximity; // 'closest' | 'standard'

  VaultModel({
    required this.id,
    this.lockerNo = '',
    required this.location,
    required this.price,
    this.slotDate = '',
    required this.timeSlot,
    this.status = 'available',
    this.size = 'small',
    this.level = 'lower',
    this.proximity = 'closest',
  });
}