/* TODO
 * 通用请求结果模型。
 *
 * [status] 请求是否成功。
 * [content] 请求成功时的业务数据。
 * [message] 接口提示信息。
 * [count] 分页类接口返回的数量字段。
 */
class ResultsType<T> {
  bool status = false;
  T? content;
  String message = '';
  int? count;
}
