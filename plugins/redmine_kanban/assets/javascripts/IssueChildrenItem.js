/* empty css                          */import{z as _,o as t,k as c,F as h,l as p,b as n,P as m,t as a,L as f,Q as k,c as I,m as y}from"./ModalsView.js";const b=(s,o)=>{const r=s.__vccOpts||s;for(const[l,e]of o)r[l]=e;return r},v={class:"issue__subject"},C=["href"],g={class:"issue__status"},x={__name:"IssueChildrenItem",props:{children:{type:Object,default:()=>null},indent:{type:Number,default:()=>16}},setup(s){return(o,r)=>{const l=_("IssueChildrenItem",!0);return t(),c("div",null,[(t(!0),c(h,null,p(s.children,(e,u)=>{var d,i;return t(),c("div",{key:u},[n("div",{class:"issue",style:k(`padding-left: ${s.indent}px !important;`)},[n("span",v,[n("a",{href:`/issues/${e.id}`,target:"_blank",class:m([e.status.is_closed?"issue closed":""])},a(e.tracker.name)+" #"+a(e.id),11,C),f(" : "+a(e.subject),1)]),n("span",g,a(`${(d=e.status)==null?void 0:d.name}`||""),1)],4),(i=e.children)!=null&&i.length?(t(),I(l,{key:0,children:e.children,indent:s.indent+12},null,8,["children","indent"])):y("",!0)])}),128))])}}},j=b(x,[["__scopeId","data-v-b953f53f"]]);export{j as default};
