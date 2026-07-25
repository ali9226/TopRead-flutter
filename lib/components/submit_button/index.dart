import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

// TODO 提交按钮
class SubmitButton extends StatefulWidget {
  final bool loading; // TODO 由父级传递
  final VoidCallback? onTap; // TODO 点击回调，可选
  final String title;

  final double margin;

  const SubmitButton({
    super.key,
    this.loading = false,
    this.margin = 0,
    this.title = "",
    this.onTap,
  });

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.margin),
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.themeColor.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: ColorConstants.themeColor,
        borderRadius: BorderRadius.circular(25),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: widget.loading ? null : widget.onTap, // loading 时禁用点击
          child: Ink(
            decoration: BoxDecoration(
              color: ColorConstants.themeColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: widget.loading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorConstants.lightTextColor,
                        ),
                      ),
                    )
                  : Text(
                      widget.title,
                      style: TextStyle(
                        color: ColorConstants.lightTextColor,
                        fontSize: 18,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
