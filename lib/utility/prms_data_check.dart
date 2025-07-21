/// PRMS 資料格式檢查工具
/// 集中管理所有資料格式驗證，方便維護與擴充。
library;

class PrmsDataCheck {
  /// 檢查員工ID（6位數字）
  static bool isValidUserId(String input) {
    final reg = RegExp(r'^\d{6}$');
    return reg.hasMatch(input);
  }

  /// 檢查機台ID（範例：13B-SACT，可依實際需求調整）
  static bool isValidMachineId(String input) {
    final reg = RegExp(r'^[A-Z0-9]+-[A-Z]+$');
    return reg.hasMatch(input);
  }

  /// 檢查PR ID（範例：PR開頭+6位數字，可依實際需求調整）
  static bool isValidPrId(String input) {
    final reg = RegExp(r'^PR\d{6}$');
    return reg.hasMatch(input);
  }

  /// 檢查Tube ID（範例：TUBE開頭+6位數字，可依實際需求調整）
  static bool isValidTubeId(String input) {
    final reg = RegExp(r'^TUBE\d{6}$');
    return reg.hasMatch(input);
  }

  /// 檢查Tube ID（範例：TUBE開頭+6位數字，可依實際需求調整）
  static bool isValidNozzleId(String input) {
    final reg = RegExp(r'^Z\d{6}$');
    return reg.hasMatch(input);
  }

  static bool isVaildRackId(String input) {
    // 假設Rack ID格式為R開頭+3位數字
    final reg = RegExp(r'^R\d{3}$');
    return reg.hasMatch(input);
    //return true;
  }
}
