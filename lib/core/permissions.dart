import 'package:physioone/hr_system/model/employee_model.dart';

enum UserRole {
  admin,          // صلاحيات كاملة
  hrManager,      // إدارة كل الموظفين، الموافقة على الإجازات والمصروفات
  departmentManager, // يرى موظفيه فقط، يوافق على طلباتهم
  employee,       // يرى ملفه الشخصي فقط
}

class Permissions {
  // الصلاحيات الأساسية
  static const String viewAllEmployees = 'view_all_employees';
  static const String viewDepartmentEmployees = 'view_department_employees';
  static const String viewOwnProfile = 'view_own_profile';
  static const String editSalary = 'edit_salary';
  static const String approveLeave = 'approve_leave';
  static const String approveExpense = 'approve_expense';
  static const String manageDocuments = 'manage_documents';
  static const String manageEmployees = 'manage_employees'; // إضافة/تعديل/حذف

  // دالة للتحقق من صلاحية معينة
  static bool hasPermission(UserRole role, String permission) {
    switch (role) {
      case UserRole.admin:
        return true; // كل الصلاحيات
      case UserRole.hrManager:
        return [
          viewAllEmployees,
          editSalary,
          approveLeave,
          approveExpense,
          manageDocuments,
          manageEmployees,
        ].contains(permission);
      case UserRole.departmentManager:
        return [
          viewDepartmentEmployees,
          approveLeave,
          approveExpense,
        ].contains(permission);
      case UserRole.employee:
        return [viewOwnProfile].contains(permission);
      default:
        return false;
    }
  }

  // دالة لتحويل النص إلى enum
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'hrmanager':
        return UserRole.hrManager;
      case 'manager':
        return UserRole.departmentManager;
      default:
        return UserRole.employee;
    }
  }

  // دالة لمعرفة ما إذا كان المستخدم يمكنه رؤية ملف موظف معين
  static bool canViewEmployee(UserRole role, String currentUserId, String targetEmployeeId, String? managerId) {
    switch (role) {
      case UserRole.admin:
      case UserRole.hrManager:
        return true;
      case UserRole.departmentManager:
        // المدير يرى نفسه وموظفيه فقط
        return currentUserId == targetEmployeeId || managerId == currentUserId;
      case UserRole.employee:
        return currentUserId == targetEmployeeId;
      default:
        return false;
    }
  }

  // دالة لمعرفة ما إذا كان المستخدم يمكنه تعديل موظف معين
  static bool canEditEmployee(UserRole role, String currentUserId, EmployeeModel employee) {
    switch (role) {
      case UserRole.admin:
      case UserRole.hrManager:
        return true;
      case UserRole.departmentManager:
        return employee.id == currentUserId || employee.managerId == currentUserId;
      case UserRole.employee:
        return false;
      default:
        return false;
    }
  }
}