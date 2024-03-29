# VideoEarner
Autoplays videos to generate income from multiple video earning websites like payup,buxmoney,workercash etc.
The script takes screenshots and finds the location and then moves the mouse to click. 
The script works for english language only at the moment.You have to select english language after signing into the websites.

## Sign Up links below
* [payupVideo](http://tinyurl.com/w4eeuthv)
* [buxMoney](http://tinyurl.com/2pseckza)
* [workerCash](http://tinyurl.com/2s48yyp6)
* [capGuru](http://tinyurl.com/yp2uz7km) 

## Prerequisites:
You will need to have linux OS along with docker installed.

For **Windows** users, a paid version of chrome extension is available.
The instructions are completely different and are mentioned along with screenshots in the downloaded file.
Please find the link [here](http://tinyurl.com/yckhaf3d)

## Demo:
[video1.webm](https://github.com/videoearn/videoearner/assets/159670470/fc066c96-37fc-4f9e-b124-eb3a49b78ef4)

## Download and run the script
Run the following commands
```
wget https://github.com/videoearn/videoearner/archive/refs/heads/main.zip
unzip main.zip
cd videoearner-main
vi properties.conf
```
Edit the properties.conf file by adding your cap.guru API key. 
Make sure to recharge your capguru account to be able to solve captchas. 

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
Set the resolution to low, if your internet speed is slow.
To use to proxy, you can install Foxyproxy extension in chrome.

To stop the script run the following command
```
sudo bash videoEarner.sh --delete
```

## FAQ

#### Why was this script written?
*This script was created solely to solicit funds, not for the purpose of gaining fame or publicity.
Many individuals have sought browser-based automation.
To get the standalone chrome extension. Click the link [here](http://tinyurl.com/yckhaf3d)*

#### What does the script do?
*The script automates video playback and utilizes an external captcha solver to resolve captchas. 
You can input the API key in the file and commence the script.
Manual login after initiating the script is deliberate to prevent misuse on websites.*

#### Does it harm websites?
*The script merely automates the human process of clicking.
You can continue watching videos while the script plays them automatically.
It does not bypass the standard process without viewing videos although it can be done by sending postMessage.*

#### Note:
The [browser code](https://github.com/chromium/chromium) is open-source, allowing users to detect any malicious code or spying activities or privacy violations or backdoors within the browser. It can be customized extensively before data leaves the network. However, customizing it according to specific requirements demands substantial prior knowledge, time, and effort.

#### Disclaimer:
The developer bears no responsibility for any misuse of the script or any ensuing consequences, whether direct, indirect, incidental, or accidental, resulting from its usage. By using this script, you assume sole responsibility. Furthermore, the developer disclaims any liability for account bans that may occur while using this script. You are permitted to modify the script as desired after downloading it. However, you are prohibited from publishing modified scripts under the same account or author name.










