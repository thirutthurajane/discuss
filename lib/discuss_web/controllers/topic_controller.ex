defmodule DiscussWeb.TopicController do
  use DiscussWeb, :controller
  alias Discuss.Discuss.Topic
  alias Discuss.Repo
  plug DiscussWeb.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_owner when action in [:edit, :update, :delete]

  def index(conn,_params) do
    topics = Repo.all(Topic)
    render conn, "index.html",topics: topics
  end

  def show(conn,  %{"id" => topic_id}) do
    topic = Repo.get!(Topic, topic_id)
    render conn, "show.html", topic: topic
  end
  # import use to give all function from module A to module B
  # alias  give shortcut to another module
  # use go and grap functionality from designate module (just like OOP class inheritance concept)
  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(conn, _params) do
    changeSet = Topic.changeset(%Topic{},%{})
    render conn, "new.html", changeset: changeSet
  end

  # Match at argument level
  def create(conn, %{"topic" => topic}) do
    # Pattern matching
    # %{"topic" => topic} = params
    # Create change set from body param
    # changeset = Topic.changeset(%Topic{}, topic)
    changeset = conn.assigns.user
      |> Ecto.build_assoc(:topic)
      |> Topic.changeset(topic)

    case Repo.insert(changeset) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Topic Created")
        |> redirect(to: Routes.topic_path(conn, :index))
      {:error, changeset} ->  render conn, "new.html", changeset: changeset
    end
  end

  def edit(conn, %{"id" => topic_id}) do
    case Repo.get(Topic, topic_id) do
      nil ->
        conn
        |> put_flash(:error, "No data to edit")
        |> redirect(to: Routes.topic_path(conn, :index))
      topic ->
        changeset = Topic.changeset(topic, %{})
        render conn, "edit.html", changeset: changeset, topic: topic
    end
  end

  def update(conn,%{"id" => topic_id,"topic" => topic}) do
    old_topic = Repo.get!(Topic, topic_id)
    changeset = Topic.changeset(old_topic, topic)
    # Cleancode version
    # changeset = Repo.get(Topic, topic_id)
    #|> Topic.changeset(topic)

    case Repo.update(changeset) do
      {:ok,_struct} ->
        conn
        |> put_flash(:info, "Topic updated")
        |> redirect(to: Routes.topic_path(conn, :index))
      {:error, changeset} ->
        render conn,"edit.html",changeset: changeset,topic: old_topic
    end
  end

  def delete(conn, %{"id" => topic_id}) do
    Repo.get!(Topic, topic_id) |> Repo.delete!

    conn
      |> put_flash(:info, "Topic deleted")
      |> redirect(to: Routes.topic_path(conn, :index))
  end

  def check_topic_owner(conn,_params) do
    %{params: %{"id" => topic_id}} = conn
      cond do
        Repo.get(Topic, topic_id) == nil ->
          conn
            |> put_flash(:error, "No data of that post")
            |> redirect(to: Routes.topic_path(conn, :index))
            |> halt()
        conn.assigns.user.id == nil ->
          conn
            |> put_flash(:error, "You can not edit that")
            |> redirect(to: Routes.topic_path(conn, :index))
            |> halt()
        Repo.get(Topic, topic_id).user_id != conn.assigns.user.id ->
          conn
            |> put_flash(:error, "You can not edit that")
            |> redirect(to: Routes.topic_path(conn, :index))
            |> halt()
        Repo.get(Topic, topic_id).user_id == conn.assigns.user.id ->
          conn
      end

  end

end
