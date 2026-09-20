<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=false; section>
    <#if section = "header">
        Passkey Ekle
    <#elseif section = "form">
        <form id="kc-passkey-offer-form" action="${url.loginAction}" method="post">
            <div class="${properties.kcFormGroupClass!}">
                <p>Hesabını daha güvenli yapmak için passkey eklemek ister misin?</p>
                <p class="${properties.kcFormHelperTextClass!}">
                    Passkey ile parmak izi, Face ID veya Windows Hello kullanarak parolasız giriş yapabilirsin.
                </p>
            </div>

            <div class="${properties.kcFormGroupClass!}">
                <button type="submit" name="passkey-choice" value="yes"
                        class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonLargeClass!}">
                    Şimdi Ekle
                </button>
                <button type="submit" name="passkey-choice" value="no"
                        class="${properties.kcButtonClass!} ${properties.kcButtonDefaultClass!} ${properties.kcButtonLargeClass!}">
                    Sonra
                </button>
            </div>
        </form>
    </#if>
</@layout.registrationLayout>

