import 'package:boats_mobile_app/components/custom_bottom_navigation.dart';
import 'package:boats_mobile_app/controllers/global_controller.dart';
import 'package:boats_mobile_app/models/current_weather_data.dart';
import 'package:boats_mobile_app/models/daily_weather_data.dart';
import 'package:boats_mobile_app/utils/background_gradient.dart';
import 'package:boats_mobile_app/utils/get_day.dart';
import 'package:boats_mobile_app/utils/string_casing_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../components/app_bar.dart';
import '../components/side_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // call the controller
  final GlobalController globalController = Get.put(
    GlobalController(),
    permanent: true,
  );
  late String currentLocation;

  @override
  void initState() {
    super.initState();
    globalController.getLocation().then((_) {
      setState(() {
        currentLocation = globalController.getCurrentLocation().value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideBar(),
      appBar: const BoatsAppBar(),
      body: SafeArea(
        child: Container(
          decoration: appBackgroundGradient(),
          child: Column(
            children: [
              Expanded(
                child: Obx(() => globalController.checkLoading().isTrue
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _weatherDashboardWidget(
                        globalController.getCurrentLocation().value,
                        globalController
                            .getWeatherData()
                            .getCurrentWeatherData(),
                        globalController
                            .getWeatherData()
                            .getDailyWeatherData())),
              ),
              const CustomBottomNavigation(
                pageIndex: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // to remove when the app will have a proper menu
  // for now the home is the weather dashboard
  Widget _weatherDashboardWidget(
      String location,
      CurrentWeatherData currentWeatherData,
      DailyWeatherData dailyWeatherData) {
    String currentDay = DateFormat('EEEE').format(DateTime.now());

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              location,
              style: GoogleFonts.lobster(fontSize: 18, color: Colors.white),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 15, right: 15, top: 5),
            padding: const EdgeInsets.only(left: 5, right: 15, top: 10),
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(
                style: BorderStyle.solid,
                width: 4,
                color: Colors.white,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            currentDay,
                            style: GoogleFonts.lobster(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Image.asset(
                            'assets/weather/${currentWeatherData.current.weather![0].icon}.png',
                            height: 80,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${currentWeatherData.current.temp}°C',
                                  style: GoogleFonts.lobster(
                                    fontSize: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Wind:',
                                  style: GoogleFonts.roboto(
                                      fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  '${currentWeatherData.current.windSpeed} KPH',
                                  style: GoogleFonts.roboto(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Humidity:',
                                  style: GoogleFonts.roboto(
                                      fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  '${currentWeatherData.current.humidity} %',
                                  style: GoogleFonts.roboto(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cloudiness:',
                                  style: GoogleFonts.roboto(
                                      fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  '${currentWeatherData.current.clouds} %',
                                  style: GoogleFonts.roboto(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  height: 50,
                  child: Text(
                    currentWeatherData.current.weather![0].description!
                        .toTitleCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            width: MediaQuery.of(context).size.width - 50,
            color: Colors.white,
            margin: const EdgeInsets.only(top: 20, bottom: 10),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            padding: const EdgeInsets.only(left: 40, right: 40),
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                    color: Colors.grey[300],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        child: Text(
                          getDay(dailyWeatherData.daily[index].dt, 'EEE'),
                          style: GoogleFonts.lobster(fontSize: 16),
                        ),
                      ),
                      Image.asset(
                        'assets/weather/${dailyWeatherData.daily[index].weather![0].icon}.png',
                        height: 30,
                        width: 30,
                      ),
                      Text(
                        '${dailyWeatherData.daily[index].temp!.min} / ${dailyWeatherData.daily[index].temp!.max}°C',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
