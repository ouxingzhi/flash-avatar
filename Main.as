﻿package
{
    import flash.external.*;
    import flash.display.*;
    import flash.events.*;
    import flash.system.*;
    import flash.ui.*;
    import model.*;
    import view.*;

    public class Main extends Sprite
    {
        private var swfStage:Stage;
        public var parameter:Object;
        public var initImgURL:String;
        public var Version:String;
        public var uid:String;
        public var cutView:CutView;
        public var avatarModel:AvatarModel;
        public var tempUploadURL:String;

        public function Main() : void
        {
            if (stage)
            {
                this.init();
            }
            else
            {
                addEventListener(Event.ADDED_TO_STAGE, this.init);
            }
            return;
        }

        private function getVersion() : String
        {
            var ver = Capabilities.version;
            var n = ver.split(",", 1);
            ver = n[0] as String;
            return ver.slice(4);
        }
        private function init() : void
        {
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            Security.allowDomain("*");
            this.swfStage = this.stage;
            this.swfStage.align = StageAlign.TOP_LEFT;
            this.swfStage.scaleMode = StageScaleMode.NO_SCALE;
			
            this.parameter = this.loaderInfo.parameters;
			/*
			用AS2时，可以直接把参数加在flash的尾部，如:demo.swf?u1=good&u2=bad
			在flash里就默认u1,u2为根变量。可以使用_root.u1和_root.u2来得到值
			但到了AS3里面这样做已经不行了。
			要用到flash.display.loaderInfo类的parameters属性，返回的是一个参数对象
			使用方法:
			例如在文档类中定义var param:Object = root.loaderInfo.parameters;
			如果取u1的值，可以用param["u1"],同样u2的值：param["u2"]
			*/
			Param.s = this.swfStage;
            Param.uid = this.parameter["uid"];
			// 默认图片地址
			Param.pSize=this.parameter["pSize"] ? (this.parameter["pSize"]) : '300|300|200|200';
			Param.pSize=(Param.pSize).split("|");
			for(var i in Param.pSize){
				Param.pSize[i]=int(Param.pSize[i]);
			}

            Param.imgUrl = this.parameter["imgUrl"] ? (this.parameter["imgUrl"]) : ("");
            Param.uploadUrl = this.parameter["uploadUrl"] ? (this.parameter["uploadUrl"]) : ("./php/saveavater.php");
            Param.filename = this.parameter["filename"] ? (this.parameter["filename"]) : ("filename");
            Param.extraParams = this.parameter["extraParams"] ? (this.parameter["extraParams"]) : {};

			if(Param.extraParams){
				try{
					Param.extraParams = JSON.parse(Param.extraParams);
				}catch(e){
					Param.extraParams = {};
				}
			}

			Param.uploadSrc = (this.parameter["uploadSrc"] == "true") ? true : false;
			Param.showBrow = (this.parameter["showBrow"] == "true") ? true : false;
			Param.showCame = (this.parameter["showCame"] == "true") ? true : false;
		
			Param.jsFunc = this.parameter["jsfunc"];
            Param.jsLang = this.parameter["jslang"];
            Param.initLanguage();
            this.Version = this.getVersion();
            this.avatarModel = new AvatarModel();
            this.cutView = new CutView(this.avatarModel);
            addChild(this.cutView);
			
			if(Param.imgUrl){
            	this.avatarModel.loaderPic(Param.imgUrl);
				this.cutView.localPicArea.loaddingUI.visible = true;
			}

            //注册js调用方法
            if (ExternalInterface.available) {
                try {
                    ExternalInterface.addCallback("jscall_updateAvatar", jscall_updateAvatar);
                }catch (e:Error){                   
                }
            }
            
            return;
        }

		//页面调用上传
		private function jscall_updateAvatar() {
			if(ExternalInterface.call(Param.jsFunc, 2) == 1)
				this.cutView.updateAvatar(null);
		}

    }
}
