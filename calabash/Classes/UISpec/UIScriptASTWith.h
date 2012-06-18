//
//  UIScriptASTWith.h
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptAST.h"
typedef enum {
    UIScriptLiteralTypeUnknown,
    UIScriptLiteralTypeIndexPath,
    UIScriptLiteralTypeString,
    UIScriptLiteralTypeInteger,
    UIScriptLiteralTypeBool
} UIScriptLiteralType;

static NSString *LP_QUERY_JS = @"(function(){function isHostMethod(object,property){var t=typeof object[property];return t==='function'||(!!(t==='object'&&object[property]))||t==='unknown';}var NODE_TYPES={1:'ELEMENT_NODE',2:'ATTRIBUTE_NODE',3:'TEXT_NODE',9:'DOCUMENT_NODE'};function computeRectForNode(object){var res={},boundingBox;if(isHostMethod(object,'getBoundingClientRect')){boundingBox=object.getBoundingClientRect();res['rect']=boundingBox;res['rect'].center_x=boundingBox.left+Math.floor(boundingBox.width/2);res['rect'].center_y=boundingBox.top+Math.floor(boundingBox.height/2);}res.nodeType=NODE_TYPES[object.nodeType]||res.nodeType+' (Unexpected)';res.nodeName=object.nodeName;res.id=object.id||'';res['class']=object.className||'';if(object.href){res.href=object.href;}if(res.nodeName.toLowerCase()==='input'){res.value=object.value;}res.html=object.outerHTML||'';res.textContent=object.textContent;return res;}function toJSON(object){var res,i,N,spanEl,parentEl;if(typeof object==='undefined'){throw {message:'Calling toJSON with undefined'};}else{if(object instanceof Text){parentEl=object.parentElement;if(parentEl){spanEl=document.createElement('calabash');spanEl.style.display='inline';spanEl.innerHTML=object.textContent;parentEl.replaceChild(spanEl,object);res=computeRectForNode(spanEl);res.nodeType=NODE_TYPES[object.nodeType];delete res.nodeName;delete res.id;delete res['class'];parentEl.replaceChild(object,spanEl);}else{res=object;}}else{if(object instanceof Node){res=computeRectForNode(object);}else{if(object instanceof NodeList||(typeof object=='object'&&object&&typeof object.length==='number'&&object.length>0&&typeof object[0]!=='undefined')){res=[];for(i=0,N=object.length;i<N;i++){res[i]=toJSON(object[i]);}}else{res=object;}}}}return res;}var exp='%@',queryType='%@',nodes=null,res=[],i,N;try{if(queryType==='xpath'){nodes=document.evaluate(exp,document,null,XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,null);for(i=0,N=nodes.snapshotLength;i<N;i++){res[i]=nodes.snapshotItem(i);}}else{res=document.querySelectorAll(exp);}}catch(e){return JSON.stringify({error:'Exception while running query: '+exp,details:e.toString()});}return JSON.stringify(toJSON(res));})();";

@interface UIScriptASTWith : UIScriptAST {
    NSString *__weak _selectorName;
    SEL _selector;
    NSObject* _objectValue;
    BOOL _boolValue;
    NSInteger _integerValue;
    
    UIScriptLiteralType _valueType;
    
}
@property (nonatomic, weak) NSString *selectorName;
@property (nonatomic,assign) SEL selector;
@property (nonatomic, assign) NSInteger timeout;
@property (nonatomic) NSObject *objectValue;
@property (nonatomic) NSObject *objectValue2;
@property (nonatomic,assign) BOOL boolValue;
@property (nonatomic,assign) BOOL boolValue2;
@property (nonatomic,assign) NSInteger integerValue;
@property (nonatomic,assign) NSInteger integerValue2;
@property (nonatomic,assign) UIScriptLiteralType valueType;
@property (nonatomic,assign) UIScriptLiteralType valueType2;
 

- (id)initWithSelectorName:(NSString *)selectorName;
@end
