package view
{
    import com.adobe.images.*; 
    import events.*;
    import flash.display.*;
    import flash.events.*;
    import flash.external.*;
    import flash.geom.*;
    import flash.net.*;
    import flash.utils.*;
    import model.*;
    import view.avatar.*;
    import view.browse.*;
    import view.camera.*;
    import view.localpic.*;

    public class CutView extends Sprite
    {
        public var splitLines:Shape;
        public var avatarArea:AvatarArea;
        public var localPicArea:LocalPicArea;
        public var avatarModel:AvatarModel;
        public var cameraArea:CameraComp;
        public var saveBtn:SK_Save;
        public var cancleBtn:SK_Cancel;
        public var cameraBtn:MovieClip;
        public var browseComp:BrowseComp;
		
		public var colorAdj:ColorAdj;
		
        public function CutView(avatarModel:AvatarModel)
        {
            this.avatarModel = avatarModel;
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
		private function init(event:Event = null) : void
        {
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.splitLines = new Shape();
            this.splitLines.graphics.lineStyle(1, 15066597);
            this.splitLines.graphics.lineTo(0, Param.pSize[1]+1000);
            this.splitLines.x = Param.pSize[0]+30;
            this.splitLines.y = 65;
            this.browseComp = new BrowseComp(this.avatarModel);
            this.browseComp.x = 20;
            this.browseComp.y = 5;
            this.cameraBtn = new SK_Camera() as MovieClip;
            this.cameraBtn.x = 155;
            this.cameraBtn.y = 5;
            this.cameraBtn.buttonMode = true;
            this.cameraBtnAddEvents();

            this.avatarArea = new AvatarArea();
            this.avatarArea.y = 40;
            this.avatarArea.x = Param.pSize[0]+40;
            this.localPicArea = new LocalPicArea();
			this.localPicArea.graphics.lineStyle(1, 15066597);
            this.localPicArea.x = 20;
            this.localPicArea.y = 40;
            addChild(this.localPicArea);	// 选择你要上传的头像的方式 提示文本区
            this.avatarModel.addEventListener(UploadEvent.IMAGE_CHANGE, this.changeAvatars);
            this.avatarModel.addEventListener(UploadEvent.IMAGE_INIT, this.initAvatars);
            addChild(this.splitLines);		// 中间分隔线
            addChild(this.avatarArea);		// 右侧头像区域
			
			//if(Param.showBrow) addChild(this.browseComp);
            //if(Param.showCame) addChild(this.cameraBtn);		// 摄像头
			addChild(this.browseComp);
            addChild(this.cameraBtn);		// 摄像头
			
			this.colorAdj = new ColorAdj();
			this.colorAdj.x = 430;
			this.colorAdj.y = 300;
			// pic param
			//addChild(this.colorAdj);
			
			initAvatars(null);
            return;
        }

        private function changeCameraBtnStatus(event:MouseEvent) : void
        {
            if (event.type == MouseEvent.MOUSE_OVER)
            {
                this.cameraBtn.gotoAndStop(2);
            }
            else
            {
                this.cameraBtn.gotoAndStop(1);
            }
            return;
        }

		// 开始上传头像
        public function updateAvatar(event:MouseEvent) : void
        {
            this.localPicArea.loaddingUI.visible = true;
			this.localPicArea.cutBox.visible = false;
			
			this.saveBtn.mouseEnabled = false;
            var _uploadUrl:String = Param.uploadUrl; // + "?action=uploadavatar&" + new Date().getTime();
			var _srcBmd = this.localPicArea._sourceBMD;
            var _bigPic = this.avatarArea.bigPic;
            var _bigBmd = _bigPic.bitmapData;
            var _newBmd = new BitmapData(Param.pSize[2], Param.pSize[3]);
				_newBmd.draw(_bigBmd, new Matrix(_bigPic.scaleX, 0, 0, _bigPic.scaleX, 0, 0), null, null, new Rectangle(0, 0, Param.pSize[2], Param.pSize[3]), true);
			_newBmd.applyFilter(_newBmd, new Rectangle(0, 0, Param.pSize[2], Param.pSize[3]), new Point(0, 0), this.colorAdj.filter);
			
			//生成编码容器
			var jpgEncoder:JPGEncoder = new JPGEncoder(100);
			//将位图数据编码到容器内成为ByteArray流
			//var jpgStream:ByteArray = jpgEncoder.encode(_srcBmd);
			
			var boundary = "---------------------------"+String(Math.random()).replace('0.','');
			
			var jpgStream = new ByteArray();
			jpgStream.writeMultiByte("--"+boundary+"\r\n", "utf8");
			jpgStream.writeMultiByte('Content-Disposition: form-data; name="'+ Param.filename +'"; filename="'+Param.filename+'.jpg"\r\n', "utf8");
			jpgStream.writeMultiByte('Content-Type: image/jpeg\r\n\r\n', "utf8");
			jpgStream.writeBytes(jpgEncoder.encode(_newBmd));
			jpgStream.writeMultiByte("\r\n--"+boundary+"--\r\n", "utf8");
			
			//if(Param.uploadSrc) jpgStream.writeBytes(jpgEncoder.encode(_srcBmd));
			
			//添加stream的header请求
			var header:URLRequestHeader = new URLRequestHeader("Content-type", "multipart/form-data; boundary="+boundary);
			var jpgURLRequest:URLRequest = new URLRequest(_uploadUrl);
			jpgURLRequest.requestHeaders.push(header);
			jpgURLRequest.method = URLRequestMethod.POST;
			jpgURLRequest.contentType = "multipart/form-data; boundary="+boundary;
			jpgURLRequest.data = jpgStream;

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, this.uploadComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, this.errorHandler);
			loader.load(jpgURLRequest);
			return;
        }

        private function cancelProgramm(event:MouseEvent) : void
        {
            this.localPicArea.loaddingUI.visible = false;
			this.localPicArea.cutBox.visible = true;
			
			this.saveBtn.mouseEnabled = true;
			
			ExternalInterface.call(Param.jsFunc, -1);
            //var reload = new URLRequest("javascript:window.location.reload(true)");
            //navigateToURL(reload, "_self");
            return;
        }

        private function initAvatars(event:UploadEvent) : void
        {
			//上传或载入成功后重置（大中小）预览框
            this.avatarArea.initAvatars(this.avatarModel.bmd);
			this.colorAdj.setImages([this.avatarArea.bigPic, this.avatarArea.midPic, this.avatarArea.smallPic]);
			if(event != null){
				this.localPicArea.setLocalPicSize(this.avatarModel.bmd);
				this.localPicArea.loaddingUI.visible = false;
				this.addSaveBtns();
			}
            return;
        }

        private function cameraBtnRemoveEvents() : void
        {
            this.cameraBtn.removeEventListener(MouseEvent.MOUSE_OUT, this.changeCameraBtnStatus);
            this.cameraBtn.removeEventListener(MouseEvent.MOUSE_OVER, this.changeCameraBtnStatus);
            this.cameraBtn.removeEventListener(MouseEvent.CLICK, this.showCameraArea);
            return;
        }


		// 上传成功，返回json
        private function uploadComplete(event:Event) : void
        {
            var _delurl:String;
            var _suc:Boolean;
            var _ticket:String;
            var evt = event;
			
            this.localPicArea.loaddingUI.visible = false;
			this.localPicArea.cutBox.visible = true;

			this.saveBtn.mouseEnabled = true;
            var loader = evt.target as URLLoader;
            loader.removeEventListener(Event.COMPLETE, this.uploadComplete);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, this.errorHandler);
			trace(loader.data);
			try{
                ExternalInterface.call(Param.jsFunc,loader.data);
            }catch (e:Error){}
			this.saveBtn.mouseEnabled = true;
        }
		
		// 上传失败
        private function errorHandler(event:IOErrorEvent) : void
        {
            this.localPicArea.loaddingUI.visible = false;
			this.localPicArea.cutBox.visible = true;
			
            var tgt = event.target as URLLoader;
            tgt.removeEventListener(IOErrorEvent.IO_ERROR, this.errorHandler);
			this.saveBtn.mouseEnabled = true;
            navigateToURL(new URLRequest("javascript:alert(\'上传失败，请重新上传。\')"), "_self");
            return;
        }

        public function cameraBtnAddEvents() : void
        {
            this.cameraBtn.addEventListener(MouseEvent.MOUSE_OVER, this.changeCameraBtnStatus);
            this.cameraBtn.addEventListener(MouseEvent.MOUSE_OUT, this.changeCameraBtnStatus);
            this.cameraBtn.addEventListener(MouseEvent.CLICK, this.showCameraArea);
            return;
        }

        private function changeAvatars(event:UploadEvent) : void
        {
            this.addSaveBtns();
            this.localPicArea.loaddingUI.visible = false;
            if (this.cameraArea != null && this.cameraArea.visible == true)
            {
                this.cameraArea.visible = false;
                this.cameraBtn.mouseEnabled = true;
                this.cameraBtn.gotoAndStop(1);
                this.cameraBtnAddEvents();
            }
            this.localPicArea.visible = true;
            this.localPicArea.setLocalPicSize(this.avatarModel.bmd);
            return;
        }
        public function showCameraArea(event:MouseEvent) : void
        {
            this.cameraBtnRemoveEvents();
            this.cameraBtn.mouseEnabled = false;
            this.cameraBtn.gotoAndStop(3);
            this.browseComp.btnBrowse.gotoAndStop(1);
            this.browseComp.btnBrowsAddEvents();
            if (this.cameraArea == null)
            {
                this.cameraArea = new CameraComp(this);
                this.cameraArea.x = 20;
                this.cameraArea.y = 40;
                addChild(this.cameraArea);
            }
            else if (this.cameraArea.visible == false)
            {
                this.cameraArea.visible = true;
            }
            this.browseComp.label.visible = false;
            this.localPicArea.visible = false;
            this.avatarArea.visible = false;
            this.splitLines.visible = false;
			this.colorAdj.visible = false;
            if (this.saveBtn != null && this.saveBtn.visible == true)
            {
                this.cancleBtn.visible = false;
                this.saveBtn.visible = false;
            }
            return;
        }

		// 创建显示保存 取消按钮
        public function addSaveBtns() : void
        {
            if (this.saveBtn == null)
            {
                this.saveBtn = new SK_Save();
				this.cancleBtn = new SK_Cancel();
                this.saveBtn.x = 430;
				this.cancleBtn.x = 520;
                this.saveBtn.y = this.cancleBtn.y = Param.pSize[1]+45;
                addChild(this.saveBtn);
                addChild(this.cancleBtn);
				// 保存按钮
				this.saveBtn.mouseEnabled = true;
				this.saveBtn.addEventListener(MouseEvent.CLICK, this.updateAvatar);
				this.cancleBtn.addEventListener(MouseEvent.CLICK, this.cancelProgramm);
            }
            return;
        }
    }
}
