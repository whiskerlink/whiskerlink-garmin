using Toybox.Lang as Lang;
using Toybox.StringUtil as StringUtil;

module TestoProtocol {
    function startupPacket1() {
        return [
            0x56, 0x00, 0x03, 0x00,
            0x00, 0x00, 0x0C, 0x69,
            0x02, 0x3E, 0x81
        ]b;
    }

    function startupPacket2() {
        return [
            0x20, 0x01, 0x00, 0x00,
            0x00, 0x00, 0x3A, 0xBB
        ]b;
    }

    function firmwareQuery() {
        return [
            0x04, 0x02, 0x15, 0x00,
            0x00, 0x00, 0x7C, 0x53,

            0x0F, 0x00, 0x00, 0x00,
            0x46, 0x69, 0x72, 0x6D,
            0x77, 0x61, 0x72, 0x65,
            0x56, 0x65, 0x72, 0x73,
            0x69, 0x6F, 0x6E,
            0x30, 0x4F
        ]b;
    }

    function streamStart549i() {
        return [
            0x11, 0x03, 0x00, 0x00,
            0x00, 0x00, 0x47, 0x5A
        ]b;
    }

    // Testo logical packets have an 8-byte header:
    // opcode, sequence, payload length LE32, header CRC LE16.
    // The payload length includes the payload CRC when present.
    function logicalPacketLength(data) {
        if (data == null || data.size() < 8) {
            return null;
        }

        var payloadLength =
              data[2]
            | (data[3] << 8)
            | (data[4] << 16)
            | (data[5] << 24);

        return 8 + payloadLength;
    }

    function findAscii(data, text) {
        if (data == null || text == null) {
            return -1;
        }

        var needle = text.toUtf8Array();

        if (needle.size() == 0 || data.size() < needle.size()) {
            return -1;
        }

        for (var i = 0; i <= data.size() - needle.size(); i += 1) {
            var matched = true;

            for (var j = 0; j < needle.size(); j += 1) {
                if (data[i + j] != needle[j]) {
                    matched = false;
                    break;
                }
            }

            if (matched) {
                return i;
            }
        }

        return -1;
    }

    function parseFirmwareVersion(data) {
        if (data == null) {
            return null;
        }

        // Firmware responses we've observed contain the printable version
        // as a run such as "2.004.17". Find a numeric/dot run with a dot.
        for (var i = 0; i < data.size(); i += 1) {
            if (!isDigit(data[i])) {
                continue;
            }

            var bytes = [];
            var hasDot = false;
            var j = i;

            while (j < data.size()) {
                var b = data[j];

                if (isDigit(b)) {
                    bytes.add(b);
                } else if (b == 0x2E) {
                    hasDot = true;
                    bytes.add(b);
                } else {
                    break;
                }

                j += 1;
            }

            if (hasDot && bytes.size() >= 5) {
                return StringUtil.utf8ArrayToString(bytes);
            }
        }

        return null;
    }

    function parseDifferentialPressurePa(data) {
        var name = "DifferentialPressure";
        var pos = findAscii(data, name);

        if (pos < 0) {
            return null;
        }

        var valueOffset = pos + name.length();

        if (valueOffset + 4 > data.size()) {
            return null;
        }

        return data.decodeNumber(
            Lang.NUMBER_FORMAT_FLOAT,
            {
                :offset => valueOffset,
                :endianness => Lang.ENDIAN_LITTLE
            }
        );
    }

    function parseBatteryPercent(data) {
        var name = "BatteryLevel";
        var pos = findAscii(data, name);

        if (pos < 0) {
            return null;
        }

        var valueOffset = pos + name.length();

        if (valueOffset + 4 > data.size()) {
            return null;
        }

        return data.decodeNumber(
            Lang.NUMBER_FORMAT_FLOAT,
            {
                :offset => valueOffset,
                :endianness => Lang.ENDIAN_LITTLE
            }
        );
    }

    function pressurePaToPsi(pa) {
        return pa / 6894.7573;
    }

    function bytesToHex(data) {
        if (data == null) {
            return "";
        }

        var result = "";
        var count = data.size();

        if (count > 8) {
            count = 8;
        }

        for (var i = 0; i < count; i += 1) {
            if (i > 0) {
                result += " ";
            }

            result += byteToHex(data[i]);
        }

        return result;
    }

    function crc16Modbus(data) {
        var crc = 0xFFFF;

        for (var i = 0; i < data.size(); i += 1) {
            crc ^= data[i];

            for (var bit = 0; bit < 8; bit += 1) {
                if ((crc & 1) != 0) {
                    crc = (crc >> 1) ^ 0xA001;
                } else {
                    crc >>= 1;
                }
            }
        }

        return crc & 0xFFFF;
    }

    function withCrc(data) {
        var result = []b;

        result.addAll(data);

        var crc = crc16Modbus(data);

        result.add(crc & 0xFF);
        result.add((crc >> 8) & 0xFF);

        return result;
    }

    function buildPacket(commandType, sequence, payload) {
        var framedPayload = []b;

        if (payload != null && payload.size() > 0) {
            framedPayload = withCrc(payload);
        }

        var header = [
            commandType,
            sequence,
            framedPayload.size() & 0xFF,
            (framedPayload.size() >> 8) & 0xFF,
            (framedPayload.size() >> 16) & 0xFF,
            (framedPayload.size() >> 24) & 0xFF
        ]b;

        var packet = withCrc(header);

        packet.addAll(framedPayload);

        return packet;
    }

    function zeroPressure(sequence) {
        var payload = [
            0x0C, 0x00, 0x00, 0x00,
            0x5A, 0x65, 0x72, 0x6F,
            0x50, 0x72, 0x65, 0x73,
            0x73, 0x75, 0x72, 0x65,
            0x01
        ]b;

        return buildPacket(0x05, sequence, payload);
    }

    function byteToHex(value) {
        var digits = "0123456789ABCDEF";

        var hi = (value >> 4) & 0x0F;
        var lo = value & 0x0F;

        return digits.substring(hi, hi + 1)
             + digits.substring(lo, lo + 1);
    }

    function isDigit(value) {
        return value >= 0x30 && value <= 0x39;
    }
}