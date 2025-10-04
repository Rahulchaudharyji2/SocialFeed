// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";



contract SocialFeed is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 likeCount;
        uint256 commentCount;
        uint256 tipAmount;
        uint256 timestamp;
    }

    struct Comment {
        address commenter;
        string content;
        uint256 timestamp;
    }

    uint256 public postCount;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment[]) public comments;

    mapping(uint256 => mapping(address => bool)) public liked;
    mapping(address => uint256) public likesReceived;
    mapping(address => uint256) public commentsReceived;
    mapping(address => uint256) public tipsReceived;

    // Events
    event PostCreated(uint256 indexed postId, address indexed author, string content, uint256 timestamp);
    event PostLiked(uint256 indexed postId, address indexed liker, uint256 timestamp);
    event CommentAdded(uint256 indexed postId, uint256 indexed commentId, address indexed commenter, string content, uint256 timestamp);
    event TipSent(uint256 indexed postId, address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event TipERC20Sent(uint256 indexed postId, address indexed from, address indexed to, address token, uint256 amount, uint256 timestamp);

    /* --- CREATE --- */
    function createPost(string calldata content) external {
        postCount++;
        posts[postCount] = Post({
            id: postCount,
            author: msg.sender,
            content: content,
            likeCount: 0,
            commentCount: 0,
            tipAmount: 0,
            timestamp: block.timestamp
        });
        emit PostCreated(postCount, msg.sender, content, block.timestamp);
    }

    /* --- LIKE --- */
    function likePost(uint256 postId) external {
        require(postId > 0 && postId <= postCount, "invalid postId");
        require(!liked[postId][msg.sender], "already liked");
        liked[postId][msg.sender] = true;
        posts[postId].likeCount++;
        likesReceived[posts[postId].author] += 1;
        emit PostLiked(postId, msg.sender, block.timestamp);
    }

    /* --- COMMENT --- */
    function commentOnPost(uint256 postId, string calldata content) external {
        require(postId > 0 && postId <= postCount, "invalid postId");
        comments[postId].push(Comment({
            commenter: msg.sender,
            content: content,
            timestamp: block.timestamp
        }));
        posts[postId].commentCount++;
        commentsReceived[posts[postId].author] += 1;
        emit CommentAdded(postId, comments[postId].length - 1, msg.sender, content, block.timestamp);
    }

    function getComments(uint256 postId) external view returns (Comment[] memory) {
        return comments[postId];
    }

    /* --- TIP NATIVE --- */
    function tipPost(uint256 postId) external payable nonReentrant {
        require(postId > 0 && postId <= postCount, "invalid postId");
        require(msg.value > 0, "no tip");
        address payable to = payable(posts[postId].author);

        posts[postId].tipAmount += msg.value;
        tipsReceived[to] += msg.value;

        (bool sent, ) = to.call{value: msg.value}("");
        require(sent, "transfer failed");

        emit TipSent(postId, msg.sender, to, msg.value, block.timestamp);
    }

    /* --- TIP ERC20 --- */
    function tipPostERC20(uint256 postId, address token, uint256 amount) external nonReentrant {
        require(postId > 0 && postId <= postCount, "invalid postId");
        require(amount > 0, "no tip");
        address to = posts[postId].author;
        IERC20(token).safeTransferFrom(msg.sender, to, amount);
        emit TipERC20Sent(postId, msg.sender, to, token, amount, block.timestamp);
    }

    /* --- GETTERS --- */
    function getPost(uint256 id) external view returns (Post memory) {
        return posts[id];
    }

    /* --- REPUTATION --- */
    function getReputation(address user) external view returns (uint256 score) {
        uint256 tips = tipsReceived[user] / 1e15; // scaled-down
        score = likesReceived[user] * 3 + commentsReceived[user] * 2 + tips;
    }
}
