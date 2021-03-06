package modules.news_demo;

import beluga.core.Beluga;
import beluga.core.Widget;
import beluga.module.account.model.User;
import beluga.module.account.Account;
import beluga.module.news.News;
import beluga.module.news.model.NewsModel;
import beluga.module.news.model.CommentModel;
import haxe.web.Dispatch;
import haxe.Resource;
import main_view.Renderer;
import sys.db.Types;

#if php
import php.Web;
#end

/**
 * @author Guillaume Gomez
 */

class NewsData {
	public var text : String;
	public var login : String;
	public var date : SDateTime;
	public var com_id : Int;

	public function new (t : String, l : String, d : SDateTime, c : Int) {
		text = t;
		login = l;
		date = d;
		com_id = c;
	}
}

class NewsList {
	public var title : String;
	public var text : String;
	public var id : Int;
	public var pos : Int;

	public function new(t : String, te : String, i : Int, p : Int) {
		title = t;
		text = te;
		id = i;
		pos = p;
		if (text.length > 200) {
			text = text.substr(0, 200) + "...";
		}
	}
}

class NewsDemo
{
	public var beluga(default, null) : Beluga;
	public var news(default, null) : News;
	private var error_msg : String;
	private var success_msg : String;

	public function new(beluga : Beluga) {
		this.beluga = beluga;
		this.news = beluga.getModuleInstance(News);
		this.error_msg = "";
		this.success_msg = "";
	}

	public static function _doDefault() {
		new NewsDemo(Beluga.getInstance()).doDefault();
	}

	public function doDefault() {
		var user = Beluga.getInstance().getModuleInstance(Account).getLoggedUser();

		var widget = news.getWidget("news");
		var t_news = this.news.getAllNews();
		var news = new Array<NewsList>();
		var pos = 0;

		for (tmp in t_news) {
			news.push(new NewsList(tmp.title, tmp.text, tmp.id, pos));
			if (pos == 0)
				pos = 1;
			else
				pos = 0;
		}
		widget.context = {news : news, error : error_msg, success : success_msg, path : "/newsDemo/", user: user};

		var newsWidget = widget.render();

		var html = Renderer.renderDefault("page_news", "News list", {
			newsWidget: newsWidget
		});
		Sys.print(html);
	}

	public static function _doPrint(args : {news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doPrint(args);
	}

	public function doPrint(args : {news_id : Int}) {
		var user = Beluga.getInstance().getModuleInstance(Account).getLoggedUser();
		var news = NewsModel.manager.get(args.news_id);

		if (news == null) {
			error_msg = "News hasn't been found...";
			doDefault();
			return;
		}
		var widget = this.news.getWidget("print");
		var t_comments = this.news.getComments(args);
		var comments = new Array<NewsData>();

		for (tmp in t_comments) {
			comments.push(new NewsData(tmp.text, tmp.user.login, tmp.creationDate, tmp.id));
		}
		widget.context = {news : news, comments : comments, path : "/newsDemo/",
							user : user, error : error_msg, success : success_msg};

		var newsWidget = widget.render();

		var html = Renderer.renderDefault("page_news", "News", {
			newsWidget: newsWidget
		});
		Sys.print(html);
	}

	public static function _doRedirect() {
		new NewsDemo(Beluga.getInstance()).doRedirect();
	}

	public function doRedirect() {
		if (Beluga.getInstance().getModuleInstance(Account).getLoggedUser() == null) {
			error_msg = "Please log in !";
			doDefault();
			return;
		}
		var widget = news.getWidget("create");
		widget.context = {path : "/newsDemo/"};

		var newsWidget = widget.render();

		var html = Renderer.renderDefault("page_news", "Create news", {
			newsWidget: newsWidget
		});
		Sys.print(html);
	}

	public static function _doRedirectEdit(args : {news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doRedirectEdit(args);
	}

	public function doRedirectEdit(args : {news_id : Int}) {
		var user = Beluga.getInstance().getModuleInstance(Account).getLoggedUser();
		if (user == null) {
			error_msg = "Please log in !";
			doDefault();
			return;
		}
		var n = NewsModel.manager.get(args.news_id);
		if (n == null || n.user_id != user.id) {
			error_msg = "You can't edit this news";
			doDefault();
			return;
		}
		var widget = news.getWidget("edit");
		widget.context = {path : "/newsDemo/", news : n, error : error_msg};

		var newsWidget = widget.render();

		var html = Renderer.renderDefault("page_news", "Create news", {
			newsWidget: newsWidget
		});
		Sys.print(html);
	}

	public static function _doCreate(args : {title : String, text : String}) {
		new NewsDemo(Beluga.getInstance()).doCreate(args);
	}

	public function doCreate(args : {title : String, text : String}) {
		this.news.create(args);
	}

	public static function _doDelete(args : {news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doDelete(args);
	}

	public function doDelete(args : {news_id : Int}) {
		this.news.delete(args);
	}

	public static function _doDeleteCom(args : {com_id : Int, news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doDeleteCom(args);
	}

	public function doDeleteCom(args : {com_id : Int, news_id : Int}) {
		this.news.deleteComment({news_id : args.news_id, comment_id : args.com_id});
	}

	public static function _doDeleteCommentFail(args : {news_id : Int, error : String}) {
		new NewsDemo(Beluga.getInstance()).doDeleteCommentFail(args);
	}

	public function doDeleteCommentFail(args : {news_id : Int, error : String}) {
		error_msg = args.error;
		this.doPrint({news_id : args.news_id});
	}

	public static function _doDeleteCommentSuccess(args : {news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doDeleteCommentSuccess(args);
	}

	public function doDeleteCommentSuccess(args : {news_id : Int}) {
		success_msg = "Comment has been deleted successfully";
		this.doPrint({news_id : args.news_id});
	}

	public static function _doCreateFail(args : {title : String, data : String, error : String}) {
		new NewsDemo(Beluga.getInstance()).doCreateFail(args);
	}

	public function doCreateFail(args : {title : String, data : String, error : String}) {
		error_msg = "Error ! News has not been created...";
		var widget = news.getWidget("create");
		widget.context = {path : "/newsDemo/", title : args.title, error : args.error, data : args.data};

		var newsWidget = widget.render();

		var html = Renderer.renderDefault("page_news", "Create news", {
			newsWidget: newsWidget
		});
		Sys.print(html);
	}
	
	public static function _doCreateSuccess() {
		new NewsDemo(Beluga.getInstance()).doCreateSuccess();
	}

	public function doCreateSuccess() {
		success_msg = "News has been successfully created !";
		this.doDefault();
	}

	public static function _doEditFail(args : {news_id : Int, error : String}) {
		new NewsDemo(Beluga.getInstance()).doEditFail(args);
	}
	
	public function doEditFail(args : {news_id : Int, error : String}) {
		error_msg = args.error;
		this.doRedirectEdit({news_id : args.news_id});
	}
	
	public static function _doEditSuccess(args : {news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doEditSuccess(args);
	}

	public function doEditSuccess(args : {news_id : Int}) {
		success_msg = "News has been successfully edited !";
		this.doPrint(args);
	}

	public static function _doAddCommentSuccess(args : {news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doAddCommentSuccess(args);
	}

	public function doAddCommentSuccess(args : {news_id : Int}) {
		success_msg = "Comment has been successfully added !";
		this.doPrint(args);
	}

	public static function _doAddCommentFail(args : {news_id : Int}) {
		new NewsDemo(Beluga.getInstance()).doAddCommentSuccess(args);
	}

	public function doAddCommentFail(args : {news_id : Int}) {
		error_msg = "Error ! Comment hasn't been added...";
		this.doPrint(args);
	}

	public static function _doDeleteSuccess() {
		new NewsDemo(Beluga.getInstance()).doDeleteSuccess();
	}

	public function doDeleteSuccess() {
		success_msg = "News has been successfully deleted !";
		this.doDefault();
	}

	public static function _doDeleteFail() {
		new NewsDemo(Beluga.getInstance()).doDeleteFail();
	}

	public function doDeleteFail() {
		error_msg = "Error: News hasn't been deleted...";
		this.doDefault();
	}

	public static function _doCreateComment(args : {news_id : Int, text : String}) {
		new NewsDemo(Beluga.getInstance()).doCreateComment(args);
	}

	public function doCreateComment(args : {news_id : Int, text : String}) {
		this.news.addComment(args);
	}

	public static function _doEdit(args : {news_id : Int, title : String, text : String}) {
		new NewsDemo(Beluga.getInstance()).doEdit(args);
	}

	public function doEdit(args : {news_id : Int, title : String, text : String}) {
		this.news.edit(args);
	}
}