defmodule ChannelServer.PageController do
  use ChannelServer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
