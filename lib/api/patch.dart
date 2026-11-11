// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app/api/dio_client.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/patch_check_result.dart';
import 'package:app/util/log_util.dart';

/* TODO
 * 热更补丁接口封装（app_patch 模块）。
 *
 * check/report 走统一加密 POST（postRequest）；
 * 补丁文件下载走独立 GET 字节流（补丁自带 Ed25519 签名，不进响应加密链路）。
 */

/// 查询补丁决策。
///
/// [file_name]/[fingerprint]/[accepted_seq]/[version_code]/[flavor]/[channel]/
/// [abi]/[strategy]/[signed] 为 FlutterPatcher.patchTarget 的设备侧信息，
/// [device_id] 为设备稳定标识（灰度分桶依据）。
/// 服务端按灰度返回补丁决策，失败或无补丁返回 null。
Future<AppPatchCheckResult?> check_app_patch({
  required String file_name,
  required String fingerprint,
  required int accepted_seq,
  required String version_code,
  required String flavor,
  required String channel,
  required String abi,
  required String strategy,
  required bool signed,
  required String device_id,
}) async {
  final ResultsType<AppPatchCheckResult> results =
      await postRequest<AppPatchCheckResult>(
        path: 'app_patch/check',
        showTips: false,
        parameter: <String, dynamic>{
          'file_name': file_name,
          'fingerprint': fingerprint,
          'accepted_seq': accepted_seq,
          'version_code': version_code,
          'flavor': flavor,
          'channel': channel,
          'abi': abi,
          'strategy': strategy,
          'signed': signed,
          'device_id': device_id,
        },
        fromJson: (Map<String, dynamic> json) =>
            AppPatchCheckResult.from_json(json),
      );

  if (!results.status || results.content == null) {
    logUtil(msg: 'patch: 查询补丁决策失败 message=${results.message}', type: 'w');
    return null;
  }
  return results.content!;
}

/// 下载补丁文件字节。
///
/// [patch_id] 补丁记录 id。成功返回文件完整字节，失败返回 null。
Future<Uint8List?> download_app_patch({required int patch_id}) async {
  try {
    final Response<dynamic> response = await DioClient().instance.get(
      '${Constant.prefix}app_patch/download',
      queryParameters: <String, dynamic>{'patch_id': patch_id},
      options: Options(
        responseType: ResponseType.bytes,
        // TODO 补丁文件可能达数 MB，放宽接收超时到 2 分钟。
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    if (response.statusCode != 200 || response.data == null) {
      logUtil(
        msg: 'patch: 下载补丁失败 patch_id=$patch_id code=${response.statusCode}',
        type: 'w',
      );
      return null;
    }

    // TODO dio 字节流返回 Uint8List 或 List<int>，统一转 Uint8List。
    final dynamic data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return null;
  } catch (e) {
    logUtil(msg: 'patch: 下载补丁异常 patch_id=$patch_id error=$e', type: 'w');
    return null;
  }
}

/// TODO 上报已确认的启动诊断，成功才允许本地移除待重试记录。
///
/// [patch_id] 补丁记录 id；[device_id] 设备稳定标识；
/// [is_healthy] 本次启动是否健康；[boot_status] 启动诊断状态（PatchBootStatus 名）。
/// TODO [diagnostic_id] 同一原生诊断的稳定幂等标识；[patch_seq] 实际诊断涉及的序号。
/// TODO [target_version_code]/[fingerprint]/[abi] 来自该补丁的宿主身份，升级丢弃时仍为旧宿主。
/// TODO [recorded_at] 原生诊断时间（毫秒），重复发送保持不变。
Future<bool> report_app_patch({
  required int patch_id,
  required String device_id,
  required bool is_healthy,
  required String boot_status,
  required String diagnostic_id,
  required String patch_seq,
  required String target_version_code,
  required int recorded_at,
  required String fingerprint,
  required String abi,
}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'app_patch/report',
        showTips: false,
        parameter: <String, dynamic>{
          'patch_id': patch_id,
          'device_id': device_id,
          'is_healthy': is_healthy,
          'boot_status': boot_status,
          'diagnostic_id': diagnostic_id,
          'patch_seq': patch_seq,
          'target_version_code': target_version_code,
          'recorded_at': recorded_at,
          'fingerprint': fingerprint,
          'abi': abi,
        },
        fromJson: (Map<String, dynamic> json) => json,
      );

  if (!results.status) {
    logUtil(msg: 'patch: 上报启动诊断失败 message=${results.message}', type: 'w');
  }
  return results.status;
}
