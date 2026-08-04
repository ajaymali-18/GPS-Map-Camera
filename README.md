void getLocation() async {
  try {
    Position position = await galleryService.getCurrentLocation();

    print("Latitude : ${position.latitude}");
    print("Longitude: ${position.longitude}");
  } catch (e) {
    print(e);
  }
}