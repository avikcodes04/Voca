import 'package:ai_app/pallete.dart';
import 'package:flutter/material.dart';

class FeatureBox extends StatelessWidget {
  const FeatureBox({
    super.key,
    required this.color,
    required this.headerText,
    required this.descriptionText,
  });
  final Color color;
  final String headerText;
  final String descriptionText;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 15, bottom: 20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                //textAlign: TextAlign.left,
                headerText,
                style: TextStyle(
                  fontFamily: "Cera Pro",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Pallete.blackColor,
                ),
              ),
            ),
            SizedBox(height: 3),
            Text(
              descriptionText,
              style: TextStyle(
                fontFamily: "Cera Pro",
                //fontSize: 18,
                //fontWeight: FontWeight.bold,
                color: Pallete.blackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
