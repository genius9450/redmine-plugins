import{a as y,X as f,y as A,G as M,H as B,o as t,k as u,b as l,c as p,w as d,t as o,e as c,Y as S,Z as w,K as C,m as h,O as D,$,P as E}from"./ModalsView.js";import{u as L}from"./columns.js";/* empty css                          */const O=()=>{const{createModal:s,createAlert:a}=y();function r(n={}){s({template:f.ADD_CUSTOM_COLUMN,...n})}function m(n={}){s({template:f.DELETE_CUSTOM_COLUMN,...n})}return{addColumn:r,deleteColumn:m,createAlert:a}},T={class:"kanban-column__header"},K={class:"kanban-column__header-title"},N={key:1,class:"kanban-column__header-title"},U=["src"],z=["onClick"],H=A({__name:"KanbanColumn",props:{element:{},hasKebab:{type:Boolean,default:!0},isAddActive:{type:Boolean,default:!1}},setup(s){const a=s,r=L(),{addColumn:m,deleteColumn:n,createAlert:b}=O(),k=M(),i=B(()=>!["unused","backlog"].includes(a.element.name.toLowerCase()));function g(e){a.element.id&&r.editColumn({column_id:a.element.id,name:e})}function v(){var e;if((e=a.element.statuses)!=null&&e.length){b({message:k.t("error_column_has_statuses")});return}m({parent_id:a.element.id})}return(e,_)=>(t(),u("div",{class:E(["kanban-column",[e.element.name.toLowerCase(),{"draggable-column":i.value}]])},[l("div",T,[i.value?(t(),p(c(S),{key:0,value:e.element.name,maxlength:255,"is-auto-grow":!1,"edit-by-focus":"","has-actions":!1,class:"kanban-column__header-editable",onChange:g},{default:d(()=>[l("p",K,o(e.element.name),1)]),_:1},8,["value"])):(t(),u("p",N,o(e.element.name),1)),e.hasKebab?(t(),p(D,{key:2,class:"kanban-column__header-kebab"},{trigger:d(()=>[l("img",{src:c(w),alt:""},null,8,U)]),content:d(()=>[e.isAddActive?(t(),u("a",{key:0,href:"",class:"fz-12",onClick:C(v,["prevent"])},o(e.$t("label_create_column")),9,z)):h("",!0),l("a",{href:"",class:"fz-12",onClick:_[0]||(_[0]=C(I=>c(n)(e.element),["prevent"]))},o(e.$t("label_delete_column")),1)]),_:1})):h("",!0)]),$(e.$slots,"default",{element:e.element})],2))}});export{H as _,O as u};
