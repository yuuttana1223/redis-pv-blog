class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @articles = Article.all
    @ranking_articles = get_ranking_articles
  end

  def show
    @article = Article.find(params[:id])
    Redis.current.zincrby "articles", 1, @article.id
    @ranking_articles = get_ranking_articles
  end

  def new
    @new_article = Article.new
  end

  def create
    @article = current_user.articles.build(article_params)
    @article.save!
    redirect_to @article
  end

  def edit
  end

  def update
    @article.update!(article_params)
    redirect_to @article
  end

  def destroy
    if @article.destroy!
      Redis.current.zrem("articles", @article.id)
    end
    redirect_to root_url
  end

  private

  def article_params
    params.require(:article).permit(:title, :content)
  end

  def correct_user
    @article = Article.find(params[:id])
    unless current_user == @article.user
      redirect_to root_url, notice: "Not yours"
    end
  end

  def get_ranking_articles
    # [[article.id, PV数(小数)], [], []]
    rankings = Redis.current.zrevrange("articles", 0, 2, with_scores: true)
    # [[articleのインスタンス, PV数(整数)], [], []]
    ranking_articles = []

    if rankings.any?
      rankings.each do |id, count|
        ranking_articles.push([Article.find(id), count.to_i])
      end
    end
    ranking_articles
  end
end
