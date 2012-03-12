(function () {
    /** David Mark's isHostMethod function,
      * http://peter.michaux.ca/articles/feature-detection-state-of-the-art-browser-scripting
      * Modified to use strict equality
      */
    function isHostMethod (object, property)
    {
      var t = typeof object[property];
      return t==='function' ||
             (!!(t==='object' && object[property])) ||
             t==='unknown';
    }
    //http://www.w3.org/TR/DOM-Level-2-Core/core.html
    var NODE_TYPES = {
        /*ELEMENT_NODE                   : */ 1 : 'ELEMENT_NODE',
        /*ATTRIBUTE_NODE                 : */ 2: 'ATTRIBUTE_NODE',
        /*TEXT_NODE                      : */ 3 : 'TEXT_NODE',
        /*DOCUMENT_NODE                  : */ 9 : 'DOCUMENT_NODE'
    };

    function toJSON(object)
    {
        var res, i, N;
        if (typeof object==='undefined')
        {
            throw {message:'Calling toJSON with undefined'};
        }
        else if (object instanceof Node)//TODO: support for frames!
        {
            res = {}
            if (isHostMethod(object,'getBoundingClientRect'))
            {
                res['rect'] = object.getBoundingClientRect();
            }
            res.nodeType = NODE_TYPES[object.nodeType] || res.nodeType + ' (Unexpected)';
            res.nodeName = object.nodeName;
            res.id = object.id || '';
            res['class'] = object.className || '';
            res.html = object.outerHTML || '';
            res.nodeValue = object.nodeValue;
        }
        else if (object instanceof NodeList || //TODO: support for frames!
                 (typeof object=='object' && object &&
                  typeof object.length === 'number' &&
                  object.length > 0 //array like
                  && typeof object[0] !== 'undefined'))
        {
            res = [];
            for (i=0,N=object.length;i<N;i++)
            {
                res[i] = toJSON(object[i]);
            }
        }
        else
        {
            res = object;
        }
        return res;
    }
    ///TODO: no support for now frames
    //idea would be map XPath across window.frames
    //must take care of visibility questions

    var exp = JSON.parse('%@')/* dynamic */,
        el,
        text = '%@',
        i,N;
    try
    {
        el=document.elementFromPoint(exp.rect.left, exp.rect.top);
        if (/input/i.test(el.tagName))
        {
            el.value = text;
        }
        else
        {

        }

    }
    catch (e)
    {
       return JSON.stringify({error:'Exception while running query: '+exp, details:e.toString()})
    }
    return JSON.stringify(toJSON(el));
})();