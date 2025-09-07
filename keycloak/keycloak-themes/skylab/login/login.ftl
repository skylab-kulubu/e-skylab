<#import "template.ftl" as layout>
<@layout.registrationLayout; section>

<#-- CSS -->
    <#if section == "styles">
        <style>
            body.login-pf-page {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                background-color: #f0f2f5 !important;
                background-size: cover !important;
                background-repeat: no-repeat !important;
                background-position: center center !important;
            }

            .login-container {
                width: 380px;
                margin: 0 auto;
                text-align: center;
                background-color: rgba(255, 255, 255, 0.6);
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 6px 16px rgba(0,0,0,0.15);
            }

            .logo-container {
                display: flex;
                justify-content: center;
                align-items: center;
                margin-bottom: 20px;
            }

            .logo-container img {
                max-width: 90px;   /* Küçültüldü */
                height: auto;
                display: block;
            }

            .logo-fallback {
                display: none;
                width: 90px;
                height: 50px;
                margin: 0 auto 20px;
                background-color: #007bff;
                color: white;
                border-radius: 8px;
                align-items: center;
                justify-content: center;
                font-weight: bold;
                font-size: 18px;
                display: flex;
            }

            .form-header h1 {
                font-size: 22px;
                color: #222;
                margin-top: 0;
                margin-bottom: 25px;
                font-weight: 600;
            }

            .form-group {
                margin-bottom: 15px;
                text-align: left;
            }

            .form-group label {
                display: block;
                margin-bottom: 6px;
                font-size: 15px;
                color: #444;
                font-weight: 500;
            }

            .form-group input {
                width: 100%;
                padding: 11px 12px;
                border: 1.5px solid #bbb;
                border-radius: 5px;
                font-size: 15px;
                box-sizing: border-box;
                transition: border-color 0.3s ease;
            }

            .form-group input:focus {
                outline: none;
                border-color: #007bff;
                box-shadow: 0 0 5px rgba(0, 123, 255, 0.5);
            }

            .login-button {
                width: 100%;
                padding: 13px;
                border: none;
                border-radius: 6px;
                background-color: #007bff;
                color: white;
                font-size: 17px;
                font-weight: 600;
                cursor: pointer;
                margin-top: 12px;
                transition: background-color 0.3s ease;
            }

            .login-button:hover {
                background-color: #0056b3;
            }

            .forgot-password {
                margin-top: 18px;
                font-size: 14px;
                text-align: center;
            }

            .forgot-password a {
                color: #007bff;
                text-decoration: none;
                font-weight: 500;
            }

            .forgot-password a:hover {
                text-decoration: underline;
            }
        </style>

    <#elseif section == "header">

        <div class="login-container">
        <div class="logo-container">
            <img id="skylab-logo" alt="Skylab Logo" />
            <div id="logo-fallback" class="logo-fallback">SKYLAB</div>
        </div>

        <div class="form-header">
            <h1>e-skylab ile giriş yap!</h1>
        </div>

    <#elseif section == "form">

        <form id="kc-form-login" action="${url.loginAction}" method="post" class="login-form" onsubmit="login.disabled=true; return true;">
            <div class="form-group">
                <label for="username" class="${properties.kcLabelClass!}">
                    Kullanıcı Adı veya E-posta
                </label>
                <input tabindex="1" id="username" name="username" class="${properties.kcInputClass!}" type="text" autofocus autocomplete="off" value="${(login.username!'')}" required/>
            </div>

            <div class="form-group">
                <label for="password" class="${properties.kcLabelClass!}">Şifre</label>
                <input tabindex="2" id="password" name="password" class="${properties.kcInputClass!}" type="password" autocomplete="off" required />
            </div>

            <button tabindex="3" type="submit" class="login-button" id="kc-login" name="login" value="Giriş Yap">
                Giriş Yap
            </button>
        </form>

        <div class="forgot-password">
            <#if realm.resetPasswordAllowed>
                <a tabindex="4" href="${url.loginResetCredentialsUrl}">Şifremi Unuttum</a>
            </#if>
        </div>

        </div>  <!-- login-container bitiş -->

    </#if>

    <script>
        // Logo yükleme
        const url = {
            resourcesPath: '${url.resourcesPath}'
        };

        const logoImg = document.getElementById('skylab-logo');
        const logoFallback = document.getElementById('logo-fallback');

        logoImg.src = `${url.resourcesPath}/img/skylab-logo.png`;
        logoImg.onerror = () => {
            logoImg.style.display = 'none';
            logoFallback.style.display = 'flex';
        };
        logoImg.onload = () => {
            logoImg.style.display = 'block';
            logoFallback.style.display = 'none';
        };

        // Body arka planı
        document.body.style.backgroundImage = `url(${url.resourcesPath}/img/background.png)`;
    </script>

</@layout.registrationLayout>