# VideoEarner
Autoplays videos to generate income from multiple video earning websites like payup,buxmoney,workercash etc.
The script takes screenshots and finds the location and then moves the mouse to click. 

## Prerequisites:
You will need to have linux OS along with docker installed.

## Download and run the script
Run the following commands
```
wget https://github.com/videoearn/videoearner/archive/refs/heads/main.zip
unzip main.zip
cd videoearner-main
vi properties.conf
```
Edit the properties.conf file by adding your cap.guru API key. 
You will get 300 free captchas on sign up. Make sure to recharge after 300 captchas.

To start the script run the following command
```
sudo bash videoEarner.sh --start
```

After starting the script, you can access the localhost url on the same linux machine if you are using GUI.
If you are only using terminal, run the following command to generate global URL using the port number.
If your port number is 3000, run the following command. Replace the port number accordingly based on the output shown in your console.

```
ssh -R 80:localhost:3000 serveo.net 
```
Access the URL to login and click start to open the video page and leave it. 
The videos play automatically and captchas are also solved. 
Just keep watching the videos and stop it manually when completed. 

To stop the script run the following command
```
sudo bash videoEarner.sh --delete
```

## FAQ

#### Why was this script written?
*This script was created solely to solicit funds, not for the purpose of gaining fame or publicity.
Many individuals have sought browser-based automation.
If you appreciate the script and have profited from it, please consider sending funds to the following address.*

#### What does the script do?
*The script automates video playback and utilizes an external captcha solver to resolve captchas. 
The Captcha Solver offers 300 free captchas upon signup. You can input the API key in the file and commence the script.
Manual login after initiating the script is deliberate to prevent misuse on websites.*

#### Does it harm websites?
*The script merely automates the human process of clicking.
You can continue watching videos while the script plays them automatically.
It does not bypass the standard process without viewing videos although it can be done by sending postMessage.*

#### Note:
The [browser code](https://github.com/chromium/chromium) is open-source, allowing users to detect any malicious code or spying activities or privacy violations or backdoors within the browser. It can be customized extensively before data leaves the network. However, customizing it according to specific requirements demands substantial prior knowledge, time, and effort.

#### Disclaimer:
The developer bears no responsibility for any misuse of the script or any ensuing consequences, whether direct, indirect, incidental, or accidental, resulting from its usage. By using this script, you assume sole responsibility. Furthermore, the developer disclaims any liability for account bans that may occur while using this script. You are permitted to modify the script as desired after downloading it. However, you are prohibited from publishing modified scripts under the same account or author name.










