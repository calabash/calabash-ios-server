//  Created by Karl Krukow on 11/09/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.

#import "LPOperation.h"

static NSString __unused *LP_SET_TEXT_JS = @"(function(){function isHostMethod(object,property){var t=typeof object[property];return t==='function'||(!!(t==='object'&&object[property]))||t==='unknown';}var NODE_TYPES={1:'ELEMENT_NODE',2:'ATTRIBUTE_NODE',3:'TEXT_NODE',9:'DOCUMENT_NODE'};function toJSON(object){var res,i,N;if(typeof object==='undefined'){throw {message:'Calling toJSON with undefined'};}else{if(object instanceof Node){res={};if(isHostMethod(object,'getBoundingClientRect')){res['rect']=object.getBoundingClientRect();}res.nodeType=NODE_TYPES[object.nodeType]||res.nodeType+' (Unexpected)';res.nodeName=object.nodeName;res.id=object.id||'';res['class']=object.className||'';res.html=object.outerHTML||'';res.nodeValue=object.nodeValue;}else{if(object instanceof NodeList||(typeof object=='object'&&object&&typeof object.length==='number'&&object.length>0&&typeof object[0]!=='undefined')){res=[];for(i=0,N=object.length;i<N;i++){res[i]=toJSON(object[i]);}}else{res=object;}}}return res;}var exp=JSON.parse('%@'),el,text='%@',i,N;try{el=document.elementFromPoint(exp.rect.left,exp.rect.top);if(/input/i.test(el.tagName)){el.value=text;}else{}}catch(e){return JSON.stringify({error:'Exception while running query: '+exp,details:e.toString()});}return JSON.stringify(toJSON(el));})();";

@interface LPSetTextOperation : LPOperation

@end
