//
//  LPWebQuery.h
//  CalabashJS
//
//  Created by Karl Krukow on 27/06/12.
//  Copyright (c) 2012 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LPWebViewProtocol.h"
#import "UIWebView+LPWebView.h"

static NSString *const LP_QUERY_JS = @"(function(){function isHostMethod(object,property){var t=typeof object[property];return t==='function'||(!!(t==='object'&&object[property]))||t==='unknown';}var NODE_TYPES={1:'ELEMENT_NODE',2:'ATTRIBUTE_NODE',3:'TEXT_NODE',9:'DOCUMENT_NODE'};var PERCENT=String.fromCharCode(37);var UNESCAPED=PERCENT+'@';function boundingClientRect(object){var rect=null,jsonRect=null;if(isHostMethod(object,'getBoundingClientRect')&&object.getClientRects().length){rect=object.getBoundingClientRect(),jsonRect={left:rect.left,top:rect.top,width:rect.width,height:rect.height,x:rect.left+Math.floor(rect.width/2),y:rect.top+Math.floor(rect.height/2)};}return jsonRect;}function computeRectForNode(object,fullDump){var res={};res.rect=boundingClientRect(object);res.nodeType=NODE_TYPES[object.nodeType]||res.nodeType+' (Unexpected)';res.nodeName=object.nodeName;res.id=object.id||'';res['class']=object.className||'';if(object.href){res.href=object.href;}if(object.hasOwnProperty('value')){res.value=object.value||'';}if(fullDump||object.nodeType==3){res.textContent=object.textContent;}return res;}function toJSON(object,fullDump,queryFrame,queryWindow){var res,i,N,spanEl,parentEl;if(typeof object==='undefined'){throw {message:'Calling toJSON with undefined'};}else{if(object instanceof queryWindow.Text){parentEl=object.parentElement;if(parentEl){spanEl=queryFrame.createElement('calabash');spanEl.style.display='inline';spanEl.innerHTML=object.textContent;parentEl.replaceChild(spanEl,object);res=computeRectForNode(spanEl,fullDump);res.nodeType=NODE_TYPES[object.nodeType];res.textContent=object.textContent;delete res.nodeName;delete res.id;delete res['class'];parentEl.replaceChild(object,spanEl);}else{res=object;}}else{if(object instanceof queryWindow.Node){res=computeRectForNode(object,fullDump);}else{if(object instanceof queryWindow.NodeList||(typeof object=='object'&&object&&typeof object.length==='number'&&object.length>0&&typeof object[0]!=='undefined')){res=[];for(i=0,N=object.length;i<N;i++){res[i]=toJSON(object[i],fullDump,queryFrame,queryWindow);}}else{res=object;}}}}return res;}function applyMethods(object,args){var length=args.length,argument;for(var i=0;i<length;i++){argument=args[i];if(typeof argument==='string'){argument={method_name:argument,args:[]};}var methodName=argument.method_name;var methodargs=argument.args;if(typeof object[methodName]==='undefined'){var type=Object.prototype.toString.call(object);object={error:'No such method: '+methodName,methodName:methodName,receiverString:object.constructor.name,receiverClass:type};break;}else{object=object[methodName].apply(object,methodargs);}}}function elementNode(node){return node.nodeType==1||node.nodeType==9;}function dumpTree(currentNode,result,queryFrame,queryWindow){var i=0,childNodes=currentNode.childNodes,N=childNodes.length,children=[],childNode;for(;i<N;i+=1){childNode=childNodes[i];if(childNode){children[i]=toJSON(childNode,false,queryFrame,queryWindow);if(elementNode(childNode)&&children[i]){dumpTree(childNode,children[i],queryFrame,queryWindow);}}}result.children=children;return result;}function fetch(exp,queryType,args,frameSelector){var queryWindow=frameSelector==''?window:document.querySelectorAll(frameSelector)[0].contentWindow,queryFrame=queryWindow.document,nodes=null,res=[],i,N;try{if(queryType=='dump'){return JSON.stringify(dumpTree(queryFrame,toJSON(queryFrame,false,queryFrame,queryWindow),queryFrame,queryWindow));}else{if(queryType==='xpath'){nodes=queryFrame.evaluate(exp,queryFrame,null,XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,null);for(i=0,N=nodes.snapshotLength;i<N;i++){res[i]=nodes.snapshotItem(i);}}else{if(queryType==='job'){return window.__CALABASH_RESULTS__[exp];}else{if(frameSelector!=''&&!queryFrame&&queryWindow){var id=window.__CALABASH_RESULTS__.length;window.__CALABASH_RESULTS__[id]=undefined;queryWindow.postMessage({__CALABASH_REQUEST__:id,exp:exp,queryType:queryType,args:args,frameSelector:''},'*');return JSON.stringify({job:id});}else{res=queryFrame.querySelectorAll(exp);}}}}}catch(e){return JSON.stringify({error:'Exception while running query: '+exp,details:e.toString()});}if(args!==UNESCAPED&&args!==''){var length=res.length;for(var i=0;i<length;i++){res[i]=applyMethods(res[i],args);}}return JSON.stringify(toJSON(res,true,queryFrame,queryWindow));}if(!window.__CALABASH_RESULTS__){window.__CALABASH_RESULTS__=[undefined];window.addEventListener('message',function(e){console.warn('MESSAGE',e);if(e.data&&e.data.__CALABASH_REQUEST__){e.source.postMessage({__CALABASH_RESPONSE__:e.data.__CALABASH_REQUEST__,result:fetch(e.data.exp,e.data.queryType,e.data.args,e.data.frameSelector)},'*');}if(e.data&&e.data.__CALABASH_RESPONSE__){window.__CALABASH_RESULTS__[e.data.__CALABASH_RESPONSE__]=e.data.result;}},false);document.addEventListener('focus',function(e){var ghostClickProtector=document.getElementById('calabashGhostClickProtector');if(!ghostClickProtector){ghostClickProtector=document.createElement('div');ghostClickProtector.id='calabashGhostClickProtector';ghostClickProtector.style.background='rgba(255,255,255,0)';ghostClickProtector.style.position='fixed';ghostClickProtector.style.left='0px';ghostClickProtector.style.top='0px';ghostClickProtector.style.width='100'+PERCENT;ghostClickProtector.style.height='100'+PERCENT;ghostClickProtector.style.zIndex='25000';document.body.appendChild(ghostClickProtector);}ghostClickProtector.style.display='block';setTimeout(function(){ghostClickProtector.style.display='none';},300);},true);}var exp='%@',queryType='%@',args='%@',frameSelector='%@';if(exp!==UNESCAPED&&exp!==''){return fetch(exp,queryType,args,frameSelector);}})();";


typedef enum : NSUInteger {
  LPWebQueryTypeCSS = 0,
  LPWebQueryTypeXPATH,
  LPWebQueryTypeFreeText,
  LPWebQueryTypeJob
} LPWebQueryType;

@interface LPWebQuery : NSObject

+ (NSArray *) arrayByEvaluatingQuery:(NSString *) query
                       frameSelector:(NSString *)frameSelector
                                type:(LPWebQueryType) type
                             webView:(UIView<LPWebViewProtocol> *) webView
                    includeInvisible:(BOOL) includeInvisible;

+ (NSDictionary *) dictionaryOfViewsInWebView:(UIView<LPWebViewProtocol> *) webView;

@end
