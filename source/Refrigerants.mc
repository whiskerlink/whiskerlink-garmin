module Refrigerants {
    const R404A = "R404A";
    const R410A = "R410A";
    const R22   = "R22";
    const R134A = "R134A";
    const R290  = "R290";

    // Tables are psig -> saturation °F via inverse linear interpolation.
    //
    // R-404A:
    // Honeywell/Genetron PT data, including separate bubble/dew values.
    //
    // R-22, R-134a, R-410A:
    // Arkema Forane pressure-temperature chart. The source chart marks
    // sub-atmospheric entries as inches Hg vacuum; those low-end values
    // are converted here to negative psig.
    //
    // R-290:
    // Parker/Sporlan Catalog 290 pressure-temperature chart.
    //
    // The 10°F spacing used for the newer tables keeps the watch resource
    // footprint small; interpolation fills the gaps.

    var _r404aTempF = [
        -60, -55, -50, -45, -40, -35, -30, -25,
        -20, -15, -10, -5, 0, 5, 10, 15,
        20, 25, 30, 35, 40, 45, 50, 55,
        60, 65, 70, 75, 80, 85, 90, 95,
        100, 105, 110, 115, 120, 125, 130, 135,
        140, 145, 150
    ];

    var _r404aBubblePsig = [
        -3.1434, -1.4243, 0.5, 2.6, 4.9, 7.5, 10.3, 13.4,
        16.8, 20.5, 24.6, 28.9, 33.7, 38.8, 44.3, 50.2,
        56.6, 63.4, 70.7, 78.6, 86.9, 95.8, 105.3, 115.3,
        126.0, 137.3, 149.3, 162.0, 175.4, 189.5, 204.5, 220.2,
        236.8, 254.2, 272.5, 291.8, 312.1, 333.3, 355.6, 379.1,
        403.7, 429.6, 456.8
    ];

    var _r404aDewPsig = [
        -3.5854, -1.9155, -0.0491, 2.0, 4.3, 6.8, 9.6, 12.7,
        16.0, 19.7, 23.6, 27.9, 32.6, 37.7, 43.1, 49.0,
        55.3, 62.1, 69.3, 77.1, 85.4, 94.2, 103.6, 113.6,
        124.2, 135.5, 147.4, 160.1, 173.4, 187.5, 202.4, 218.1,
        234.6, 252.1, 270.4, 289.8, 309.9, 331.2, 353.5, 377.1,
        401.7, 427.7, 455.1
    ];

    var _commonTempF = [
        -50, -40, -30, -20, -10, 0, 10, 20, 30, 40, 50,
        60, 70, 80, 90, 100, 110, 120, 130, 140, 150
    ];

    // R-22. -50°F is 6.1 inHg vacuum -> -2.996 psig.
    var _r22Psig = [
        -2.996, 0.6, 4.9, 10.2, 16.5, 24.0, 32.8, 43.1,
        55.0, 68.6, 84.1, 101.6, 121.4, 143.6, 168.4, 195.9,
        226.4, 260.0, 296.9, 337.4, 381.7
    ];

    // R-134a. Values below its normal boiling point were vacuum readings
    // in the source and are converted to negative psig.
    var _r134aPsig = [
        -9.1846, -7.2691, -4.8133, -1.8173, 1.9, 6.5, 11.9, 18.4,
        26.1, 35.0, 45.4, 57.4, 71.1, 86.7, 104.3, 124.2,
        146.4, 171.2, 198.7, 229.2, 262.9
    ];

    // R-410A is a near-azeotropic blend with negligible glide for normal
    // service work, so WhiskerLink presents one saturation temperature.
    var _r410aPsig = [
        5.0, 10.8, 17.8, 26.3, 36.5, 48.4, 62.4, 78.7,
        97.4, 118.8, 143.2, 170.7, 201.8, 236.5, 275.4, 318.6,
        366.4, 419.4, 477.9, 542.5, 613.9
    ];

    var _r290TempF = [
        -40, -30, -20, -10, 0, 10, 20, 30, 40, 50,
        60, 70, 80, 90, 100, 110, 120, 130, 140
    ];

    var _r290Psig = [
        1.42, 5.67, 10.7, 16.7, 23.7, 31.8, 41.1, 51.8, 63.9, 77.6,
        93.0, 110.2, 129.3, 150.5, 173.9, 199.6, 227.8, 258.7, 292.3
    ];

    function displayName(refrigerant) {
        if (refrigerant == null) {
            return "R-404A";
        }

        if (refrigerant.equals(R404A)) { return "R-404A"; }
        if (refrigerant.equals(R410A)) { return "R-410A"; }
        if (refrigerant.equals(R22))   { return "R-22"; }
        if (refrigerant.equals(R134A)) { return "R-134a"; }
        if (refrigerant.equals(R290))  { return "R-290"; }

        return "Unknown";
    }

    function lookup(refrigerant, pressurePsi) {
        if (refrigerant == null || pressurePsi == null) {
            return null;
        }

        if (refrigerant.equals(R404A)) {
            var dewF = _temperatureForPressure(
                pressurePsi,
                _r404aDewPsig,
                _r404aTempF
            );

            var bubbleF = _temperatureForPressure(
                pressurePsi,
                _r404aBubblePsig,
                _r404aTempF
            );

            if (dewF == null || bubbleF == null) {
                return null;
            }

            return {
                :saturationF => null,
                :dewF => dewF,
                :bubbleF => bubbleF
            };
        }

        if (refrigerant.equals(R410A)) {
            return _pureResult(
                _temperatureForPressure(
                    pressurePsi,
                    _r410aPsig,
                    _commonTempF
                )
            );
        }

        if (refrigerant.equals(R22)) {
            return _pureResult(
                _temperatureForPressure(
                    pressurePsi,
                    _r22Psig,
                    _commonTempF
                )
            );
        }

        if (refrigerant.equals(R134A)) {
            return _pureResult(
                _temperatureForPressure(
                    pressurePsi,
                    _r134aPsig,
                    _commonTempF
                )
            );
        }

        if (refrigerant.equals(R290)) {
            return _pureResult(
                _temperatureForPressure(
                    pressurePsi,
                    _r290Psig,
                    _r290TempF
                )
            );
        }

        return null;
    }

    function _pureResult(saturationF) {
        if (saturationF == null) {
            return null;
        }

        return {
            :saturationF => saturationF,
            :dewF => null,
            :bubbleF => null
        };
    }

    function _temperatureForPressure(pressure, pressures, temperatures) {
        if (pressure < pressures[0]
            || pressure > pressures[pressures.size() - 1]) {
            return null;
        }

        for (var i = 0; i < pressures.size() - 1; i += 1) {
            var p0 = pressures[i];
            var p1 = pressures[i + 1];

            if (pressure >= p0 && pressure <= p1) {
                var t0 = temperatures[i];
                var t1 = temperatures[i + 1];

                if (p1 == p0) {
                    return t0.toFloat();
                }

                var fraction = (pressure - p0) / (p1 - p0);
                return t0 + ((t1 - t0) * fraction);
            }
        }

        return null;
    }
}