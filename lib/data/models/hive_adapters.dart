import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'budget_model.dart';
import 'category_icon_helper.dart';
import 'transaction_model.dart';

class TxTypeAdapter extends TypeAdapter<TxType> {
  @override
  final int typeId = 0;

  @override
  TxType read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < TxType.values.length) {
      return TxType.values[index];
    }
    return TxType.expense;
  }

  @override
  void write(BinaryWriter writer, TxType obj) {
    writer.writeByte(obj.index);
  }
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final iconCodePoint = reader.readInt();
    final colorValue = reader.readInt();
    final typeIndex = reader.readByte();

    final txType = (typeIndex >= 0 && typeIndex < TxType.values.length)
        ? TxType.values[typeIndex]
        : TxType.expense;

    return CategoryModel(
      id: id,
      name: name,
      icon: CategoryIconHelper.getIcon(name, iconCodePoint),
      color: Color(colorValue),
      type: txType,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.icon.codePoint);
    writer.writeInt(obj.color.toARGB32());
    writer.writeByte(obj.type.index);
  }
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 2;

  @override
  TransactionModel read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final amount = reader.readDouble();
    final typeIndex = reader.readByte();
    final category = reader.read() as CategoryModel;
    final dateMillis = reader.readInt();
    final hasNote = reader.readBool();
    final note = hasNote ? reader.readString() : null;
    final paymentMethod = reader.readString();
    final isRecurring = reader.readBool();

    final hasReceipt = reader.readBool();
    final receiptPath = hasReceipt ? reader.readString() : null;

    final hasDebtPerson = reader.readBool();
    final debtPerson = hasDebtPerson ? reader.readString() : null;

    final hasDueDate = reader.readBool();
    final debtDueDate = hasDueDate
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;

    final isDebtSettled = reader.readBool();

    final hasRecurringDay = reader.readBool();
    final recurringDay = hasRecurringDay ? reader.readInt() : null;

    final hasEndDate = reader.readBool();
    final recurringEndDate = hasEndDate
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;

    final hasRecurringTag = reader.readBool();
    final recurringTag = hasRecurringTag ? reader.readString() : null;

    final txType = (typeIndex >= 0 && typeIndex < TxType.values.length)
        ? TxType.values[typeIndex]
        : TxType.expense;

    return TransactionModel(
      id: id,
      title: title,
      amount: amount,
      type: txType,
      category: category,
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      note: note,
      paymentMethod: paymentMethod,
      isRecurring: isRecurring,
      receiptPath: receiptPath,
      debtPerson: debtPerson,
      debtDueDate: debtDueDate,
      isDebtSettled: isDebtSettled,
      recurringDay: recurringDay,
      recurringEndDate: recurringEndDate,
      recurringTag: recurringTag,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeByte(obj.type.index);
    writer.write(obj.category);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.note != null);
    if (obj.note != null) {
      writer.writeString(obj.note!);
    }
    writer.writeString(obj.paymentMethod);
    writer.writeBool(obj.isRecurring);

    writer.writeBool(obj.receiptPath != null);
    if (obj.receiptPath != null) {
      writer.writeString(obj.receiptPath!);
    }

    writer.writeBool(obj.debtPerson != null);
    if (obj.debtPerson != null) {
      writer.writeString(obj.debtPerson!);
    }

    writer.writeBool(obj.debtDueDate != null);
    if (obj.debtDueDate != null) {
      writer.writeInt(obj.debtDueDate!.millisecondsSinceEpoch);
    }

    writer.writeBool(obj.isDebtSettled);

    writer.writeBool(obj.recurringDay != null);
    if (obj.recurringDay != null) {
      writer.writeInt(obj.recurringDay!);
    }

    writer.writeBool(obj.recurringEndDate != null);
    if (obj.recurringEndDate != null) {
      writer.writeInt(obj.recurringEndDate!.millisecondsSinceEpoch);
    }

    writer.writeBool(obj.recurringTag != null);
    if (obj.recurringTag != null) {
      writer.writeString(obj.recurringTag!);
    }
  }
}

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 3;

  @override
  BudgetModel read(BinaryReader reader) {
    final id = reader.readString();
    final category = reader.read() as CategoryModel;
    final limit = reader.readDouble();
    final spent = reader.readDouble();
    final period = reader.readString();

    return BudgetModel(
      id: id,
      category: category,
      limit: limit,
      spent: spent,
      period: period,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer.writeString(obj.id);
    writer.write(obj.category);
    writer.writeDouble(obj.limit);
    writer.writeDouble(obj.spent);
    writer.writeString(obj.period);
  }
}
