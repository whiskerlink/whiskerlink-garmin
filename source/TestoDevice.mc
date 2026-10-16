using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as WatchUi;

class TestoDevice {
    const STATE_IDLE = 0;
    const STATE_WAIT_RX1 = 1;
    const STATE_WAIT_RX2 = 2;
    const STATE_WAIT_FIRMWARE = 3;
    const STATE_WAIT_STREAM = 4;
    const STATE_STREAMING = 5;

    var _device;
    var _model;

    var _uuidFff0;
    var _uuidFff1;
    var _uuidFff2;

    var _writeChar = null;
    var _notifyChar = null;
    var _cccd = null;

    var _state = STATE_IDLE;
    var _rxBuffer = []b;

    var _nextSequence = 4;

    var _firmware = null;
    var _pressurePsi = null;
    var _batteryPercent = null;

    // Connect IQ characteristic writes are limited to 20 bytes.
    // Testo logical packets may be larger, so queue 20-byte chunks and
    // send the next chunk only after the previous write callback.
    var _txChunks = [];
    var _txChunkIndex = 0;

    function initialize(device, model, uuidFff0, uuidFff1, uuidFff2) {
        _device = device;
        _model = model;

        _uuidFff0 = uuidFff0;
        _uuidFff1 = uuidFff1;
        _uuidFff2 = uuidFff2;
    }

    function start() {
        _state = STATE_IDLE;
        _rxBuffer = []b;
        _txChunks = [];
        _txChunkIndex = 0;

        var service = _device.getService(_uuidFff0);

        if (service == null) {
            setStatus("FFF0 missing");
            return;
        }

        _writeChar = service.getCharacteristic(_uuidFff1);
        _notifyChar = service.getCharacteristic(_uuidFff2);

        if (_writeChar == null) {
            setStatus("FFF1 missing");
            return;
        }

        if (_notifyChar == null) {
            setStatus("FFF2 missing");
            return;
        }

        _cccd = _notifyChar.getDescriptor(Ble.cccdUuid());

        if (_cccd == null) {
            setStatus("CCCD missing");
            return;
        }

        setStatus("Enabling notify");
        _cccd.requestWrite([0x01, 0x00]b);
    }

    function onDescriptorWrite(descriptor, status) {
        if (_cccd == null) {
            return;
        }

        if (!descriptor.getUuid().equals(Ble.cccdUuid())) {
            return;
        }

        if (status != Ble.STATUS_SUCCESS) {
            setStatus("Notify err " + status);
            return;
        }

        sendStartupPacket1();
    }

    function sendStartupPacket1() {
        _state = STATE_WAIT_RX1;
        setStatus("Handshake 1/4");
        writePacket(TestoProtocol.startupPacket1());
    }

    function sendStartupPacket2() {
        _state = STATE_WAIT_RX2;
        setStatus("Handshake 2/4");
        writePacket(TestoProtocol.startupPacket2());
    }

    function sendFirmwareQuery() {
        _state = STATE_WAIT_FIRMWARE;
        setStatus("Reading firmware");
        writePacket(TestoProtocol.firmwareQuery());
    }

    function sendStreamStart() {
        _state = STATE_WAIT_STREAM;
        setStatus("Starting stream");
        writePacket(TestoProtocol.streamStart549i());
    }

    function writePacket(packet) {
        if (_writeChar == null) {
            setStatus("No FFF1");
            return;
        }

        _txChunks = [];
        _txChunkIndex = 0;

        var offset = 0;

        while (offset < packet.size()) {
            var chunk = []b;
            var end = offset + 20;

            if (end > packet.size()) {
                end = packet.size();
            }

            for (var i = offset; i < end; i += 1) {
                chunk.add(packet[i]);
            }

            _txChunks.add(chunk);
            offset = end;
        }

        sendNextTxChunk();
    }

    function sendNextTxChunk() {
        if (_txChunkIndex >= _txChunks.size()) {
            return;
        }

        var chunk = _txChunks[_txChunkIndex];

        _writeChar.requestWrite(
            chunk,
            {
                :writeType => Ble.WRITE_TYPE_DEFAULT
            }
        );
    }

    function onCharacteristicWrite(characteristic, status) {
        if (_writeChar == null) {
            return;
        }

        if (!characteristic.getUuid().equals(_uuidFff1)) {
            return;
        }

        if (status != Ble.STATUS_SUCCESS) {
            setStatus("TX err " + status);
            _txChunks = [];
            _txChunkIndex = 0;
            return;
        }

        _txChunkIndex += 1;

        if (_txChunkIndex < _txChunks.size()) {
            sendNextTxChunk();
            return;
        }

        _txChunks = [];
        _txChunkIndex = 0;
    }

    function onCharacteristicChanged(characteristic, value) {
        if (_notifyChar == null) {
            return;
        }

        if (!characteristic.getUuid().equals(_uuidFff2)) {
            return;
        }

        if (value == null) {
            return;
        }

        // BLE notification boundaries are not Testo packet boundaries.
        // Accumulate bytes and peel off complete logical Testo packets.
        _rxBuffer.addAll(value);
        processReceiveBuffer();
    }

    function processReceiveBuffer() {
        while (_rxBuffer.size() >= 8) {
            var totalLength = TestoProtocol.logicalPacketLength(_rxBuffer);

            if (totalLength == null || totalLength < 8) {
                setStatus("Bad RX frame");
                _rxBuffer = []b;
                return;
            }

            if (_rxBuffer.size() < totalLength) {
                return;
            }

            var packet = []b;

            for (var i = 0; i < totalLength; i += 1) {
                packet.add(_rxBuffer[i]);
            }

            var remainder = []b;

            for (var j = totalLength; j < _rxBuffer.size(); j += 1) {
                remainder.add(_rxBuffer[j]);
            }

            _rxBuffer = remainder;
            handlePacket(packet);
        }
    }

    function handlePacket(packet) {
        if (_state == STATE_WAIT_RX1) {
            // Known-good response:
            // 07 00 00 00 00 00 01 AC
            sendStartupPacket2();
            return;
        }

        if (_state == STATE_WAIT_RX2) {
            sendFirmwareQuery();
            return;
        }

        if (_state == STATE_WAIT_FIRMWARE) {
            var version = TestoProtocol.parseFirmwareVersion(packet);

            if (version != null) {
                _firmware = version;
                _model.serviceUuid = "FW " + version;
                WatchUi.requestUpdate();

                sendStreamStart();
            }

            return;
        }

        if (_state == STATE_WAIT_STREAM) {
            // TX4 normally gets an acknowledgement before the async stream.
            // If this packet is already live data, parse it before switching.
            _state = STATE_STREAMING;
            setStatus("Streaming");
            handleLivePacket(packet);
            return;
        }

        if (_state == STATE_STREAMING) {
            handleLivePacket(packet);
        }
    }

    function handleLivePacket(packet) {
        var pressurePa = TestoProtocol.parseDifferentialPressurePa(packet);

        if (pressurePa != null) {
            _pressurePsi = TestoProtocol.pressurePaToPsi(pressurePa);

            _model.deviceName =
                "P " + _pressurePsi.format("%.1f") + " psi";
        }

        var battery = TestoProtocol.parseBatteryPercent(packet);

        if (battery != null) {
            _batteryPercent = battery;
            _model.raw =
                "Battery " + _batteryPercent.format("%.0f") + "%";
        }

        if (pressurePa != null || battery != null) {
            _model.status = "549i streaming";
            WatchUi.requestUpdate();
        }
    }

    function zeroPressure() {
        if (_state != STATE_STREAMING) {
            setStatus("Not streaming");
            return;
        }

        var packet = TestoProtocol.zeroPressure(_nextSequence);

        _nextSequence += 1;

        if (_nextSequence > 255) {
            _nextSequence = 0;
        }

        setStatus("Zeroing...");
        writePacket(packet);
    }

    function setStatus(text) {
        _model.status = text;
        WatchUi.requestUpdate();
    }
}