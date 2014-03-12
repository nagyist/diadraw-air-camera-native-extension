/** 
 * Native camera extension library 
 * @author Radoslava Leseva, diadraw.com
 */ 

package com.diadraw.extensions.camera
{
	import flash.events.Event;
	
	public class NativeCameraExtensionEvent extends Event
	{
		public static var IMAGE_READY 	: String = "IMAGE_READY";
		public static var STATUS_EVENT 	: String = "STATUS_EVENT";
		public static var CAMERA_STARTED 	: String = "CAMERA_STARTED";
		
		
		public function NativeCameraExtensionEvent( _type 		: String, 
													_message 	: String = "", 
													_data 		: String = "", 
													_bubbles 	: Boolean = false, 
													_cancelable : Boolean = false )
		{
			super( _type, _bubbles, _cancelable );	
			m_message = _message;
			m_data = _data;
		}
		
		
		public function get message() : String
		{
			return m_message;
		}
		
		
		public function get data() : String
		{
			return m_data;
		}
		
		
		public function get frameWidth() : Number
		{
			return m_frameWidth;
		}
		
		
		public function set frameWidth( _w : Number ) : void
		{
			m_frameWidth = _w;
		}
		
		public function get frameHeight() : Number
		{
			return m_frameHeight;
		}
		
		
		public function set frameHeight( _h : Number ) : void
		{
			m_frameHeight = _h;
		}
		
		
		private var m_message : String;
		private var m_data : String;
		private var m_frameWidth : Number;
		private var m_frameHeight : Number;
	}
}