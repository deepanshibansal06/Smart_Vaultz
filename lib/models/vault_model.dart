class VaultModel {
  final String id;
  final String lockerNo;
  final String location;
  final double price;
  final String slotDate;
  final String timeSlot;
  final String status; // 'available' | 'booked'

  VaultModel({
    required this.id,
    this.lockerNo = '',
    required this.location,
    required this.price,
    this.slotDate = '',
    required this.timeSlot,
    this.status = 'available',
  });
}