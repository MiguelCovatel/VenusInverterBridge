#!/bin/sh
svc -t /service/VenusInverterBridge 2>/dev/null || svc -u /service/VenusInverterBridge 2>/dev/null || true
