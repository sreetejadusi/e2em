import 'dart:io';

class SavedDeviceModel {
  String id;
  String name;
  SavedDeviceModel({required this.id, required this.name});

  factory SavedDeviceModel.fromDocument(Map<String, dynamic> doc) {
    return SavedDeviceModel(
      id: doc['id'],
      name: doc['name'],
    );
  }

  Map<String, dynamic> toMap() {
    final doc = <String, dynamic>{};
    doc['id'] = id;
    doc['name'] = name;
    return doc;
  }
}
