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
  // static bool isValidMachineId(String input) {
  //   final reg = RegExp(r'^[A-Z0-9]+-[A-Z]+$');
  //   return reg.hasMatch(input);
  // }

  /// 檢查機台ID（規則：A開頭、總長6~8碼、其餘只能大寫英數）
  static bool isValidMachineId(String input) {
    final reg = RegExp(r'^A[A-Z0-9]{5,7}$');
    return reg.hasMatch(input);
  }

  /// 檢查PR ID（範例：L開頭+6位數字+連字號+12位數字）
  static bool isValidPrId(String input) {
    final reg = RegExp(r'^L\d{6}-\d{12}$');
    return reg.hasMatch(input);
  }

  /// 檢查 Tube ID
  /// 支援格式：
  /// 1. L207350.2   => L + 6位數字 + . + 1位數字
  /// 2. L235220B.0  => L + 6位數字 + 1位英文/數字 + . + 1位數字
  static bool isValidTubeId(String input) {
    final normalReg = RegExp(r'^L\d{6}\.\d$');
    final extendedReg = RegExp(r'^L\d{6}[A-Za-z0-9]\.\d$');

    return normalReg.hasMatch(input) || extendedReg.hasMatch(input);
  }

  /// 檢查Nozzle ID（範例：1_2，數字+底線+數字）
  static bool isValidNozzleId(String input) {
    final reg = RegExp(r'^\d+_\d+$');
    return reg.hasMatch(input);
  }

  static bool isValidRackId(String input) {
    // Rack ID格式：數字字母-MFG-P+數字-字母數字
    final reg = RegExp(r'^[0-9A-Z]+-MFG-P\d+-[A-Z0-9]+$');
    // 2B-MFG-P005-A2
    return reg.hasMatch(input);
    //return true;
  }
}
