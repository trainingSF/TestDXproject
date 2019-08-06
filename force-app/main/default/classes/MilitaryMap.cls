
public with sharing class MilitaryMap {
    // static variable to determine if geocoding    has already occurred
    private static Boolean geocodingCalled = false;

// wrapper method to prevent calling future methods from an existing future context
    public static void doAddressGeocode(id accountId) {
        if (geocodingCalled || System.isFuture()) {
            System.debug(LoggingLevel.WARN, '***Address Geocoding Future Method Already Called - Aborting...');
            return;
        }
// if        not being called from future context, geocode the address
        geocodingCalled = true;
        geocodeAddress(accountId);
    }

    // we need a future method to call Google    Geocoding API from Salesforce
    @future(callout=true)
    static private void geocodeAddress(id accountId) {
        // Key        for Google Maps Geocoding API
        String geocodingKey = '[__Your_API_key_from_Google__]';
        // get        the passed in address
        Account geoAccount = [
                SELECT Geolocation__c, Address__c
                FROM Account
                WHERE id = :accountId
        ];

        //        check that we have enough information to geocode the address
        if (geoAccount.Address__c == null) {
            System.debug(LoggingLevel.WARN, 'Insufficient Data to Geocode Address');
            return;
        }
//        create a string for the address to pass to Google Geocoding API
        String geoAddress = '';
        if (geoAccount.Address__c != null)
            geoAddress += geoAccount.Address__c;

//        encode the string so we can pass it as part of URL
        geoAddress = EncodingUtil.urlEncode(geoAddress, 'UTF-8');
//        build and make the callout to the Geocoding API
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?address='
                +
                geoAddress + '&key=' + geocodingKey
                + '&sensor=false');
        request.setMethod('GET');
        request.setTimeout(60000);
        try {
//            make the http callout
            HttpResponse response = http.send(request);
//            parse JSON to extract co-ordinates
            JSONParser responseParser = JSON.createParser(response.getBody());
//            initialize co-ordinates
            double latitude = null;
            double longitude = null;
            while (responseParser.nextToken() != null) {
                if ((responseParser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                        (responseParser.getText() == 'location')) {
                    responseParser.nextToken();
                    while (responseParser.nextToken() != JSONToken.END_OBJECT) {
                        String locationText = responseParser.getText();
                        responseParser.nextToken();
                        if (locationText == 'lat')
                            latitude = responseParser.getDoubleValue(); else if (locationText == 'lng')
                            longitude = responseParser.getDoubleValue();
                    }
                }
            }
//            update co - ordinates on address if we get them back
            if (latitude != null) {
                geoAccount.Geolocation__Latitude__s = latitude;
                geoAccount.Geolocation__Latitude__s = longitude;
                update geoAccount;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                    'Error Geocoding Address - ' + e.getMessage());
        }
    }

    public static void createAddressByMarkup(Decimal latitude, Decimal longitude) {

    }


}