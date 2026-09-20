package com.skylab.nativehandoff;

@FunctionalInterface
interface NativeBridgeRedeemer {
    NativeBridgeIdentity redeem(String bridgeCode) throws Exception;
}
